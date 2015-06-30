module Shrike
  module Permissions

    class SimpleConstrain < Constrain

      def initialize(property, value, hash={})
        self.property = property.to_s
        self.value = value
        self.relation = hash[:relation]
        self.table_name = hash[:table_name]
      end

    end

  end
end
