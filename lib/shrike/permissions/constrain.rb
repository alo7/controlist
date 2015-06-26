module Shrike
  module Permissions

    class Constrain
      attr_accessor :property, :value, :relation, :table_name, :type, :operator, :clause
    end

  end
end

