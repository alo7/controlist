module Shrike

  class Handler

    @permissions

    class << self

      attr_accessor :permission_provider

      def handle(*clazz)

        ActiveRecord::Relation.class_eval do
          def build_arel_with_shrike
            raise "Shrike::Handler.permission_provider is nil" if Shrike::Handler.permission_provider.nil?
            unless @has_shrike
              self.instance_variable_set(:@has_shrike, true)
              permission_package = Shrike::Handler.permission_provider.get_permission_package(@klass)
              permissions = permission_package.list_read
              if permissions.empty?
                self.where!("1 != 1")
              else
                permissions.each do |permission|
                  self.where!("#{permission.sql}") if permission.sql
                end
              end
            else
              puts ">>>>>>>>>>>>>>>>>>>>>>#{@klass} 0>>>>>>>>>>>>"
            end
            build_arel_without_shrike
          end
          alias_method_chain :build_arel, :shrike unless method_defined? :build_arel_without_shrike
        end

      end

    end

  end

end
