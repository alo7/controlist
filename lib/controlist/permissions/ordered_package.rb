module Controlist
  module Permissions

    class OrderedPackage

      attr_reader :list_create, :list_read, :list_update, :list_delete, :permissions

      def initialize(*permissions)
        permissions.compact!
        @list_create = {}
        @list_read = {}
        @list_update = {}
        @list_delete = {}
        @permissions = permissions
        @permissions.freeze # avoid bypassing add_permissions/remove_permissions
        add_permissions(*permissions)
      end

      def add_permissions(*permissions)
        @permissions += permissions
        @permissions.freeze
        permissions.each do |permission|
          operations = permission.operations
          add @list_create, permission if operations.nil? || operations.include?(CREATE)
          add @list_read, permission if operations.nil? ||  operations.include?(READ)
          add @list_update, permission if operations.nil? ||  operations.include?(UPDATE)
          add @list_delete, permission if operations.nil? ||  operations.include?(DELETE)
        end
      end

      def remove_permissions(*permissions)
        @permissions -= permissions
        @permissions.freeze
        permissions.each do |permission|
          operations = permission.operations
          remove @list_create, permission if operations.nil? || operations.include?(CREATE)
          remove @list_read, permission if operations.nil? ||  operations.include?(READ)
          remove @list_update, permission if operations.nil? ||  operations.include?(UPDATE)
          remove @list_delete, permission if operations.nil? ||  operations.include?(DELETE)
        end
      end

      def has_permission(klass, operation)
        permission_list = instance_variable_get("@list_#{operation}")
        if permission_list && (permissions = permission_list[klass])
          permissions.any?(&:is_allowed)
        end
      end

      private

      def add(list, permission)
        (list[permission.klass] ||= []) << permission
      end

      def remove(list, permission)
        (list[permission.klass] ||= []).delete permission
      end

    end

  end
end
