module Shrike
  module Permissions

    class AdvancedConstrain < Constrain

      def initialize(hash)
        self.property = hash[:property]
        self.value = hash[:value]
        self.relation = hash[:relation]
        self.table_name = hash[:table_name]
        self.operator = hash[:operator]
        self.clause = hash[:clause]
        self.proc_read = hash[:proc_read]
        self.proc_persistence = hash[:proc_persistence]
      end

    end

  end
end
