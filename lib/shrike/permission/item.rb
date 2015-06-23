module Shrike
  module Permission
    class Item

      attr_accessor :klass, :operations, :is_allowed, :constrains, :clause, :joins, :checked_properties
      ##
      # constrain includes :property, :value, :operator(default =), :relation, :clause

      def initialize(klass, operations, is_allowed = true, constrains=nil)
        self.klass = klass
        unless operations.nil?
          if operations.is_a? Array
            self.operations = operations
          else
            self.operations = [operations]
          end
        end
        self.is_allowed = is_allowed
        self.joins = []
        if self.operations.nil?
          init_for_read constrains
          init_for_persistence constrains
        else
          init_for_read constrains if self.operations.include? Shrike::Permission::READ
          if  self.operations.include?(Shrike::Permission::CREATE) ||
              self.operations.include?(Shrike::Permission::UPDATE) ||
              self.operations.include?(Shrike::Permission::DELETE)
            init_for_persistence constrains
          end
        end
      end

      def handle_for_read(relation)
        if self.clause
          if self.joins.size > 0
            relation.joins!(*self.joins) 
          end
          relation.where!("#{self.clause}")
        end
      end

      def check_for_persistence(object)
        raise PermissionError.new
      end

      private

      def init_for_persistence(constrains)
        return if constrains.nil?
        if !(constrains.is_a?(Hash) ||constrains.is_a?(Array))
          raise ArgumentError.new("constrains has unknown type #{constrains.class}")
        end
        constrains = [constrains] if constrains.is_a? Hash
        constrains.each do |constrain|
        end
      end

      def init_for_read(constrains)
        return if constrains.nil?
        case constrains
        when String
          self.clause = constrains
        when Array, Hash
          constrains = [constrains] if constrains.is_a? Hash
          self.constrains = constrains
          self.clause = build_clause
          self.clause = "not (#{self.clause})" if self.is_allowed == false
        else
          raise ArgumentError.new("constrains has unknown type #{constrains.class}")
        end
      end

      def build_clause
        clause = ""
        self.constrains.each do |constrain|
          if constrain.is_a?(AdvancedConstrain) && !constrain.clause.nil?
            part_clause = constrain.clause
          else
            table_name = append_joins constrain.relation if constrain.relation
            table_name ||= (constrain.table_name || self.klass.table_name)
            property = constrain.property
            value = constrain.value
            raise ArgumentError.new("property could not be nil") if property.nil?
            raise ArgumentError.new("value could not be nil") if value.nil?
            raise "value require string type" unless value.is_a? String
            if value.upcase == 'NULL'
              default_operator = 'is'
            else
              value = "'#{value}'" if constrain.type.nil? || constrain.type == String
              default_operator = '='
            end
            operator = constrain.operator || default_operator
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
