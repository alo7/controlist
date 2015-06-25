require 'shrike/value_object'
module Shrike

  class Handler

    class << self

      def handle
        hook_read
        hook_persistence
        hook_attribute
      end

      # Avoid ActiveModel::MissingAttributeError due to select(attributes) according to constrains
      def hook_attribute
        ActiveRecord::Persistence.class_eval %Q{
          def #{Shrike.attribute_proxy}(attr)
            self.#{Shrike.value_object_proxy}[attr]
          end

          def #{Shrike.value_object_proxy}
            @#{Shrike.value_object_proxy} ||= ValueObject.build_for self
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
                    raise PermissionError.new("Permissions Empty")
                  else
                    passed = false
                    permissions.each do |permission|
                      if permission.match_for_persistence(self, Shrike::Permission::#{operation.upcase})
                        Shrike.logger.debug "Shrike matched to \#{permission.is_allowed ? 'allow' : 'forbid'} \#{permission.inspect}"
                        passed = true if permission.is_allowed
                        break
                      end
                    end
                    if passed
                      Shrike.logger.debug "Shrike #{operation} checked: PASSED"
                    else
                      Shrike.logger.debug "Shrike #{operation} checked: FORBIDDEN"
                      raise PermissionError.new("Forbidden") 
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

    end

  end

end
