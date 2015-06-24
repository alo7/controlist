module Shrike
  module Permission
    class Item


      ##
      # constrain is SimpleConstrain or AdvancedConstrain
      # for read, is_allowed is used in clause
      # for persistence, is_allowed is used in property checking
      attr_accessor :klass, :operations, :is_allowed, :constrains, :clause, :joins, :properties

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

      def apply(*properties)
        self.properties = properties
        unless self.properties.blank?
          self.properties << klass.primary_key
        end
        self
      end

      def handle_for_read(relation)
        relation._select!(*self.properties) unless self.properties.blank?
        relation.joins!(*self.joins) if self.joins.size > 0
        relation.where!("#{self.clause}") if self.clause
      end

      def match_constains_for_persistence(object)
        self.constrains.any? do |constrain|
          matched = false
          property = constrain.property
          value = constrain.value
          if !property.nil? && !value.nil?
            if object.persisted?
              changes = object.changes[property]
              matched = true if changes && changes.first == value
            else
              matched = true if object[property] == value
            end
          end
          matched
        end
      end

      private

      def init_for_persistence(constrains)
        if constrains.nil?
          self.constrains = []
          return
        else
          if !(constrains.is_a?(Constrain) ||constrains.is_a?(Array))
            raise ArgumentError.new("constrains has unknown type #{constrains.class}")
          end
          constrains = [constrains] if constrains.is_a? Constrain
          constrains.each do |constrain|
            raise "Persistence checking only for SimpleConstrain, but got #{constrain}" if !constrain.instance_of?(SimpleConstrain)
          end
          self.constrains = constrains
        end
      end

      def init_for_read(constrains)
        return if constrains.nil?
        case constrains
        when String
          self.clause = constrains
        when Array, Constrain
          constrains = [constrains] if constrains.is_a? Constrain
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
