module Shrike
  module Permission
    class Item

      attr_accessor :klass, :operation, :is_allowed, :constrains, :clause, :joins
      ##
      # constrain includes :property, :value, :operator(default =), :relation, :clause

      def initialize(klass, operation, is_allowed = true, constrains=nil)
        self.klass = klass
        self.operation = operation
        self.is_allowed = is_allowed
        self.joins = []
        case constrains
        when String
          self.clause = constrains
        when Array, Hash
          constrains = [constrains] if Hash === constrains
          self.constrains = constrains
          self.clause = build_clause
          self.clause = "not (#{self.clause})" if self.is_allowed == false
        else
          raise ArgumentError.new("constrains has unknown type #{constrains.class}") unless constrains.nil?
        end
      end

      def build_clause
        clause = ""
        self.constrains.each do |constrain|
          part_clause = constrain[:clause]
          if part_clause.nil?
            table_name = append_joins constrain[:relation] if constrain[:relation]
            table_name ||= (constrain[:table_name] || self.klass.table_name)
            property = constrain[:property]
            value = constrain[:value]
            raise ArgumentError.new("property could not be nil") if property.nil?
            raise ArgumentError.new("value could not be nil") if value.nil?
            raise "value require string type" unless String === value
            default_operator = value.upcase == "NULL" ? 'is' : "="
            operator = constrain[:operator] || default_operator
            part_clause = "#{table_name}.#{property} #{operator} #{value}"
          end
          clause += " and " if clause.length > 0
          clause += "(#{part_clause})"
        end
        clause
      end

      def append_joins(relation_name)
        reflections = self.klass.reflections
        # Rails 4.2 use string key, instead Rails 4.1 use symbol key
        relation = reflections[relation_name.to_s] || reflections[relation_name.to_sym]
        raise "Relation #{relation_name} Not found for class #{self.klass}!" if relation.nil?
        self.joins << relation_name.to_sym
        relation.table_name
      end


    end
  end
end
