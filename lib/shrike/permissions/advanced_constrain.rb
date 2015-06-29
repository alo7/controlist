module Shrike
  module Permissions

    class AdvancedConstrain < SimpleConstrain

      attr_accessor :clause

      def initialize(hash)
        super(hash[:property], hash[:value], hash)
        self.operator = hash[:operator]
        self.clause = hash[:clause]
        self.proc = Proc.new if block_given?
      end

    end

  end
end
