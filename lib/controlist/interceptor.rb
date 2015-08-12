module Controlist

  class Interceptor

    PROXY_CLASSES = {}

    class << self

      def hook
        hook_read
        hook_persistence
        hook_attribute
      end

      # used by hook_attribute
      def build_proxy(target)
        klass = target.class
        proxy_class = (PROXY_CLASSES[klass] ||= create_value_object_proxy_class klass)
        proxy_class.new target
      end

      private

      def hook_attribute
        ActiveRecord::Persistence.class_eval %Q{
          def #{Controlist.attribute_proxy}(attr)
            self.#{Controlist.value_object_proxy}[attr]
          end

          def #{Controlist.value_object_proxy}
            @#{Controlist.value_object_proxy} ||= Controlist::Interceptor.build_proxy self
          end
        }
      end

      def hook_persistence
        if Controlist.is_activerecord3?
          settings = {
            create: :create,
            update: :update,
            delete: [:delete, :destroy]
          }
        else
          settings = {
            create: :_create_record,
            update: :_update_record,
            delete: [:delete, :destroy]
          }
        end
        settings.each do |operation, methods|
          Array(methods).each do |method|
            ActiveRecord::Persistence.module_eval %Q{
              def #{method}_with_controlist(*args)
                permission_manager = Controlist.permission_manager
                unless permission_manager.skip?
                  permission_package = permission_manager.get_permission_package
                  permissions = permission_package.list_#{operation}[self.class] if permission_package
                  if permissions.blank?
                    raise NoPermissionError
                  else
                    passed = false
                    matched_permission = nil
                    permissions.each do |permission|
                      if permission.match_for_persistence(self, Controlist::Permission::#{operation.upcase})
                        Controlist.debug{"Controlist matched to \#{permission.is_allowed ? 'allow' : 'forbid'} \#{permission.inspect}"}
                        if permission.is_allowed
                          passed = true
                        end
                        matched_permission = permission
                        break
                      end
                    end
                    if passed
                      Controlist.debug{"Controlist #{operation} checked: PASSED"}
                    else
                      Controlist.debug{"Controlist #{operation} checked: FORBIDDEN"}
                      if matched_permission.nil?
                        raise NoPermissionError
                      else
                        raise PermissionForbidden.new "Forbidden by permission", matched_permission
                      end
                    end
                  end
                end
                # Avoid effect fetching arel in original update method
                Controlist.skip { #{method}_without_controlist(*args) }
              end
              alias_method_chain :#{method}, :controlist unless method_defined? :#{method}_without_controlist
            }
        end
      end
    end

    def hook_read
      if Controlist.is_activerecord3?
        ActiveRecord::QueryMethods.module_eval do
          def _select!(*value)
            self.select_values += Array.wrap(value)
          end
        end
        #Avoid id based cache
        ActiveRecord::IdentityMap.module_eval do
          def self.enabled?
            false
          end
          def self.enabled
            false
          end
        end
      else
        ActiveRecord::Core::ClassMethods.module_eval do
          #Bypass find_by_statement_cache, otherwise will use cached sql which may has wrong permissions
          def find(*args)
            super
          end
          def find_by(*args)
            super
          end
        end
      end
      ActiveRecord::Relation.class_eval do
        def real_build_arel_with_controlist
          relation = self
          permission_manager = Controlist.permission_manager
          permission_package = permission_manager.get_permission_package
          permissions = permission_package.list_read[@klass] if permission_package
          if permissions.blank?
            relation = self.where("1 != 1")
          else
            permissions.each do |permission|
              relation = permission.handle_for_read relation
            end
          end
          relation.send(:build_arel_without_controlist)
        end
        def build_arel_with_controlist
          permission_manager = Controlist.permission_manager
          if permission_manager.skip?
            build_arel_without_controlist
          else
            self.real_build_arel_with_controlist
          end
        end
        alias_method_chain :build_arel, :controlist unless method_defined? :build_arel_without_controlist
      end
    end

    def create_value_object_proxy_class(klass)
      attributes = klass.columns.map(&:name)
      attributes.delete klass.primary_key
      proxy_class = Class.new
      code_block = ""
      attributes.each do |attribute|
        code_block += %Q{
            def #{attribute}
              @target.#{attribute} rescue nil
            end
        }
      end
      proxy_class.class_eval %Q{
          def initialize(target)
            @target = target
          end
          def [](attribute)
            @target[attribute] rescue nil
          end
      #{code_block}
      }
      proxy_class
    end

  end

end

end
