class AdvancedConstrain < SimpleConstrain

  attr_accessor :clause

  def initialize(hash)
    super(hash[:property], hash[:value], hash)
    self.type = hash[:type] if hash[:type]
    self.operator = hash[:operator]
    self.clause = hash[:clause]
  end

end
