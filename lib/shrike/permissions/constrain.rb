module Shrike
  module Permissions

    class Constrain
      attr_accessor :property, :value, :relation, :table_name, :operator, :clause, :proc_read, :proc_persistence
    end

  end
end

