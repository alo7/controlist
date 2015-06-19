module Shrike
  module Permission
    class Item

      attr_accessor :klass, :operation, :is_allowed, :property, :operator, :value, :table_name, :sql
      def initialize(klass, operation, hash={})
        self.klass = klass
        self.operation = operation
        self.table_name = hash[:table_name] || klass.table_name
        self.is_allowed = hash[:is_allowed] || true
        self.property = hash[:property]
        if property.nil?
          self.sql = hash[:sql]
        else
          self.value = hash[:value]
          self.operator = hash[:operator] || '='
          if self.value.nil?
            if self.operator.include?("is")
              self.sql = "#@table_name.#@property is NULL"
            else
              self.sql = "#@table_name.#@property #@operator NULL"
            end
          else
            self.sql = "#@table_name.#@property #@operator #@value"
          end
          self.sql = "not (#@sql)" if self.is_allowed == false
        end
      end

    end
  end
end
