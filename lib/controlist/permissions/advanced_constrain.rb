module Controlist
  module Permissions

    class AdvancedConstrain < Constrain

      def initialize(hash)
        self.property = hash[:property].to_s
        self.value = hash[:value]
        self.relation = hash[:relation]
        self.table_name = hash[:table_name]
        self.operator = hash[:operator]
        self.clause = hash[:clause]
        if Controlist.is_activerecord3? && (hash.has_key?(:proc_read) || hash.has_key?(:proc_persistence))
          raise NotImplementedError, "Skip proc_read and proc_persistence, that features only be supported in ActiveRecord 4 or later"
        else
          self.proc_read = hash[:proc_read]
          self.proc_persistence = hash[:proc_persistence]
        end
      end

    end

  end
end
