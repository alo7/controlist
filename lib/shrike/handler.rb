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
        ActiveRecord::Persistence.class_eval do
          def _val(attr)
            self._value_object[attr]
          end

          def _value_object
            @_value_object ||= ValueObject.build_for self
          end
        end
      end

      def hook_persistence
        {
          list_create: :_create_record,
          list_update: :_update_record,
          list_delete: [:delete, :destroy]
        }.each do |package_list, methods|
          Array(methods).each do |method|
            ActiveRecord::Persistence.module_eval %Q{
              def #{method}_with_shrike(*args)
                permission_provider = Shrike.permission_provider
                unless permission_provider.skip?
                  permission_package = permission_provider.get_permission_package
                  permissions = permission_package.#{package_list}[self.class] if permission_package
                  if permissions.blank?
                    raise PermissionError.new("Permissions Empty")
                  else
                    passed = false
                    p permissions
                    permissions.each do |permission|
                      if permission.match_constains_for_persistence(self)
                        passed = true if permission.is_allowed
                        break
                      end
                    end
                    raise PermissionError.new("Forbidden") unless passed
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
