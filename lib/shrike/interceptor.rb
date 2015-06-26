module Shrike

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

      # Avoid ActiveModel::MissingAttributeError due to select(attributes) according to constrains
      #   #suppose attribute_proxy is :_val, value_object_proxy is :_value_object
      #   user = User.find 1
      #   user._val(:name)
      #   user._value_object.name
      def hook_attribute
        ActiveRecord::Persistence.class_eval %Q{
          def #{Shrike.attribute_proxy}(attr)
            self.#{Shrike.value_object_proxy}[attr]
          end

          def #{Shrike.value_object_proxy}
            @#{Shrike.value_object_proxy} ||= Shrike::Interceptor.build_proxy self
          end
        }
      end

      def hook_persistence
        {
          create: :_create_record,
          update: :_update_record,
          delete: [:delete, :destroy]
        }.each do |operation, methods|
          Array(methods).each do |method|
            ActiveRecord::Persistence.module_eval %Q{
              def #{method}_with_shrike(*args)
                permission_provider = Shrike.permission_provider
                unless permission_provider.skip?
                  permission_package = permission_provider.get_permission_package
                  permissions = permission_package.list_#{operation}[self.class] if permission_package
                  if permissions.blank?
                    raise NoPermissionError
                  else
                    passed = false
                    matched_permission = nil
                    permissions.each do |permission|
                      if permission.match_for_persistence(self, Shrike::Permission::#{operation.upcase})
                        Shrike.logger.debug{"Shrike matched to \#{permission.is_allowed ? 'allow' : 'forbid'} \#{permission.inspect}"}
                        if permission.is_allowed
                          passed = true
                        end
                        matched_permission = permission
                        break
                      end
                    end
                    if passed
                      Shrike.logger.debug{"Shrike #{operation} checked: PASSED"}
                    else
                      Shrike.logger.debug{"Shrike #{operation} checked: FORBIDDEN"}
                      if matched_permission.nil?
                        raise NoPermissionError
                      else
                        raise PermissionForbidden.new "Forbidden by permission", matched_permission
                      end
                    end
                  end
                end
                #{method}_without_shrike(*args)
              end
              alias_method_chain :#{method}, :shrike unless method_defined? :#{method}_without_shrike
            }
          end
        end
      end

      def hook_read
        ActiveRecord::Core::ClassMethods.module_eval do
          #Bypass find_by_statement_cache, otherwise will use cached sql which may has wrong permissions
          def find(*args)
            super
          end
          def find_by(*args)
            super
          end
        end
        ActiveRecord::Relation.class_eval do
          def build_arel_with_shrike
            permission_provider = Shrike.permission_provider
            unless permission_provider.skip?
              permission_package = permission_provider.get_permission_package
              permissions = permission_package.list_read[@klass] if permission_package
              if permissions.blank?
                self.where!("1 != 1")
              else
                permissions.each do |permission|
                  permission.handle_for_read self
                end
              end
            end
            build_arel_without_shrike
          end
          alias_method_chain :build_arel, :shrike unless method_defined? :build_arel_without_shrike
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
