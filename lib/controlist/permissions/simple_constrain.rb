module Controlist
  module Permissions

    class SimpleConstrain < Constrain

      def initialize(property, value)
        self.property = property.to_s
        self.value = value
      end

    end

  end
end
