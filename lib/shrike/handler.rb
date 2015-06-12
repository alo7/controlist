module Shrike

  class Handler

    class << self

      def handle(model)
        puts ">>>>>>>>>>>>>>1>>>>>>>>>>>>>>"

        model.instance_eval do
          puts ">>>>>>>>>>>>>>2>>>>>>>>>>>>>>"
          puts ">>>>>>>>>>>>>>#{method_defined? :build_arel_without_shrike}>>>>>>>>>>>>>>"
          alias_method_chain :build_arel, :shrike unless method_defined? :build_arel_without_shrike
          def build_arel_with_shrike
            puts ">>>>>>>>>>>>>>>>>>>>>>3>>>>>>>>>>>>>>>>>>>>"
            build_arel_without_shrike
          end
        end

      end

    end

  end

end
