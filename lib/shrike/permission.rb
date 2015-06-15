module Shrike
  module Permission

    OPERATIONS = [:create, :read, :update, :delete]

    class Package

      attr_reader :list_create, :list_read, :list_update, :list_delete

      def initialize(permissions=[])
        @list_create = []
        @list_read = []
        @list_update = []
        @list_delete = []
        permissions.select{|permission| permission.operation == :create}
                   .each{|permission| add_list_create permission}
        permissions.select{|permission| permission.operation == :read}
                   .each{|permission| add_list_read permission}
        permissions.select{|permission| permission.operation == :update}
                   .each{|permission| add_list_update permission}
        permissions.select{|permission| permission.operation == :delete}
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

    class Item
      attr_accessor :klass, :operation, :is_allowed, :property, :operator, :value, :table_name
      attr_reader :sql
      def initialize(klass, operation, property=nil, value=nil, is_allowed=true, operator=nil, table_name=nil)
        self.klass = klass
        self.table_name = table_name || klass.table_name
        self.operation = operation
        self.is_allowed = is_allowed
        self.property = property
        self.value = value
        self.operator = operator || '='
        unless property.nil?
          if value.nil?
            if operator.include?("is")
              @sql = "#@table_name.#@property is NULL"
            else
              @sql = "#@table_name.#@property #@operator NULL"
            end
          else
            @sql = "#@table_name.#@property #@operator #@value"
          end
          @sql = "not (#@sql)" if is_allowed == false
        end
      end
    end

  end
end
