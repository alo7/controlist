require 'shrike/permissions/operation'
require 'shrike/permissions/constrain'
require 'shrike/permissions/simple_constrain'
require 'shrike/permissions/advanced_constrain'
require 'shrike/permissions/ordered_package'

module Shrike
  class Permission

    ##
    # constrain is SimpleConstrain or AdvancedConstrain
    # properties is hash with property and value pairs, operation READ only need keys
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
        init_for_read constrains if self.operations.include? Shrike::Permissions::READ
        if  self.operations.include?(Shrike::Permissions::CREATE) ||
            self.operations.include?(Shrike::Permissions::UPDATE) ||
            self.operations.include?(Shrike::Permissions::DELETE)
          init_for_persistence constrains
        end
      end
    end

    def apply(*properties)
      self.properties = {id: nil}
      properties.each do |property_pair|
        if property_pair.is_a? Hash
          self.properties.merge! property_pair
        else
          self.properties[property_pair] = nil
        end
      end
      self
    end

    def handle_for_read(relation)
      relation._select!(*self.properties.keys) unless self.properties.blank?
      relation.joins!(*self.joins) if self.joins.size > 0
      relation.where!("#{self.clause}") if self.clause
    end

    def match_for_persistence(object, operation)
      properties_matched = match_properties_for_persistence object, operation
      properties_matched && match_constains_for_persistence(object, operation)
    end

    def match_properties_for_persistence(object, operation)
      return true if operation == Shrike::Permissions::DELETE || self.properties.blank?
      properties_matched = false
      changes = object.changes
      self.properties.each do |property, value|
        change = changes[property]
        if change && (value.nil? || Array(value).include?(change.last))
          properties_matched = true
          break
        end
      end
      Shrike.logger.debug{"Shrike #{operation} properties checked: #{properties_matched}"}
      properties_matched
    end

    # Only SimpleConstrains accepted from init_for_persistence
    def match_constains_for_persistence(object, operation)
      if self.constrains.blank?
        constrain_matched = true
      else
        constrain_matched = self.constrains.any? do |constrain|
          inner_matched = false
          property = constrain.property
          value = constrain.value
          if constrain.relation.nil?
            if object.persisted? && (changes = object.changes[property])
              inner_matched = changes.first == value
            else
              inner_matched = object[property] == value
            end
          else
            relation_object = object.send(constrain.relation)
            inner_matched = (relation_object && relation_object[property] == value)
          end
          inner_matched
        end
      end
      Shrike.logger.debug{"Shrike #{operation} constrains checked: #{constrain_matched}"}
      constrain_matched
    end

    private

    def init_for_persistence(constrains)
      if constrains.nil?
        self.constrains = []
        return
      else
        if !(constrains.is_a?(Shrike::Permissions::Constrain) ||constrains.is_a?(Array))
          raise ArgumentError.new("constrains has unknown type #{constrains.class}")
        end
        constrains = [constrains] if constrains.is_a? Shrike::Permissions::Constrain
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
      when Array, Shrike::Permissions::Constrain
        constrains = [constrains] if constrains.is_a? Shrike::Permissions::Constrain
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
        if constrain.is_a?(Shrike::Permissions::AdvancedConstrain) && !constrain.clause.nil?
          part_clause = constrain.clause
        else
          table_name = append_joins constrain.relation if constrain.relation
          table_name ||= (constrain.table_name || self.klass.table_name)
          property = constrain.property
          value = constrain.value
          raise ArgumentError.new("property could not be nil") if property.blank?
          raise ArgumentError.new("value could not be nil") if value.blank?
          default_operator = '='
          if value.is_a?(Proc) && value.lambda?
            Shrike.skip{ value = value.call }
          end
          if value.is_a? Array
            if value.first.is_a? String
              value = "('" + value.join("','") + "')"
            else
              value = "(" + value.join(",") + ")"
            end
            default_operator = 'in'
          else
            if value.is_a? String
              if value.upcase == 'NULL'
                default_operator = 'is' 
              else
                value = "'#{value}'"
              end
            end
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
