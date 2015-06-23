module Shrike

  class Handler

    class << self

      def handle
        hook_read
        hook_update
      end

      def hook_update
        ActiveRecord::Persistence.module_eval do
          def _update_record_with_shrike(*args)
            unless @has_shrike
              self.instance_variable_set(:@has_shrike, true)
              permission_package = Shrike.permission_provider.get_permission_package
              permissions = permission_package.list_update[self.class] if permission_package
              if permissions.blank?
                raise PermissionError.new("Permissions Empty")
              else
                permissions.each do |permission|
                  unless permission.check_for_persistence(self)
                    raise PermissionError.new("Forbidden due to #{permission.inspect}")
                  end
                end
              end
            end
            _update_record_without_shrike(*args)
          end
          alias_method_chain :_update_record, :shrike unless method_defined? :_update_record_without_shrike
        end
      end

      def hook_read
        ActiveRecord::Relation.class_eval do
          def build_arel_with_shrike
            unless @has_shrike
              self.instance_variable_set(:@has_shrike, true)
              permission_package = Shrike.permission_provider.get_permission_package
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
