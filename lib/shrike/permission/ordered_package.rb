module Shrike
  module Permission

    class OrderedPackage

      attr_reader :list_create, :list_read, :list_update, :list_delete

      def initialize(*permissions)
        @list_create = {}
        @list_read = {}
        @list_update = {}
        @list_delete = {}
        add_permissions *permissions
      end

      def add_permissions(*permissions)
        permissions.select{|permission| permission.operations.nil? || permission.operations.include?(CREATE)}
                   .each{|permission| add_list_create permission}
        permissions.select{|permission| permission.operations.nil? || permission.operations.include?(READ)}
                   .each{|permission| add_list_read permission}
        permissions.select{|permission| permission.operations.nil? || permission.operations.include?(UPDATE)}
                   .each{|permission| add_list_update permission}
        permissions.select{|permission| permission.operations.nil? || permission.operations.include?(DELETE)}
                   .each{|permission| add_list_delete permission}
      end

      def add_list_create(permission)
        (@list_create[permission.klass] ||= []) << permission
      end

      def add_list_read(permission)
        (@list_read[permission.klass] ||= []) << permission
      end

      def add_list_update(permission)
        (@list_update[permission.klass] ||= []) << permission
      end

      def add_list_delete(permission)
        (@list_delete[permission.klass] ||= []) << permission
      end

    end

  end
end
