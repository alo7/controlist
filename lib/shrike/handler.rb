module Shrike

  class Handler

    class << self

      def handle

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
                  if permission.clause
                    if permission.joins.size > 0
                      self.joins!(*permission.joins) 
                    end
                    self.where!("#{permission.clause}")
                  end
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
