module Shrike
  module Permission
    class Item

      attr_accessor :klass, :operation, :is_allowed, :constrains, :table_name, :sql
      ##
      # constrain includes :property, :value, :operator(default =), :is_allowed

      class << self
        def build_sql(constrains, klass)
          sql = ""
          constrains.each do |constrain|
            property = constrain[:property]
            raise ArgumentError.new("property could not be nil") if property.nil?
            value = constrain[:value]
            operator = constrain[:operator] || '='
            table_name = constrain[:table_name] || klass.table_name
            if value.nil?
              # process is/is not NULL
              if operator.include?("is")
                part_sql = "(#{table_name}.#{property} is NULL)"
              else
                part_sql = "#{table_name}.#{property} #{operator} NULL"
              end
            else
              raise "value require string type" unless String === value
              part_sql = "#{table_name}.#{property} #{operator} #{value}"
            end
            part_sql = "not (#{part_sql})" if constrain[:is_allowed] == false
            sql += " and " if sql.length > 0
            sql += "(#{part_sql})"
          end
          sql
        end
      end

      def initialize(klass, operation, constrains=nil)
        self.klass = klass
        self.operation = operation
        case constrains
        when String
          self.sql = constrains
        when Array, Hash
          constrains = [constrains] if Hash === constrains
          self.constrains = constrains
          self.sql = self.class.build_sql(self.constrains, self.klass)
        else
          raise ArgumentError.new("constrains has unknown type #{constrains.class}") unless constrains.nil?
        end
      end


    end
  end
end
