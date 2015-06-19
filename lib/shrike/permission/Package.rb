module Shrike
  module Permission

    class Package

      attr_reader :list_create, :list_read, :list_update, :list_delete

      def initialize(permissions=[])
        @list_create = []
        @list_read = []
        @list_update = []
        @list_delete = []
        permissions.select{|permission| permission.operation == CREATE}
                   .each{|permission| add_list_create permission}
        permissions.select{|permission| permission.operation == READ}
                   .each{|permission| add_list_read permission}
        permissions.select{|permission| permission.operation == UPDATE}
                   .each{|permission| add_list_update permission}
        permissions.select{|permission| permission.operation == DELETE}
                   .each{|permission| add_list_delete permission}
      end

      def add_list_create(permission)
        @list_create << permission
      end

      def add_list_read(permission)
        @list_read << permission
      end

      def add_list_update(permission)
        @list_update << permission
      end

      def add_list_delete(permission)
        @list_delete << permission
      end

    end

  end
end
