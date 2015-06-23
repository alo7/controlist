class SimpleConstrain

  attr_accessor :property, :value, :relation, :table_name, :type, :operator, :clause

  def initialize(property, value = nil, hash={})
    self.property = property
    self.value = value
    self.relation = hash[:relation]
    self.table_name = hash[:table_name]
    self.type = nil
    self.operator = nil
    self.clause = nil
  end

end
