module Shrike
  module ValueObject

    HANDLERS = {}

    def self.build_for(target)
      klass = target.class
      handler = (HANDLERS[klass] ||= create_handler klass)
      handler.new target
    end

    def self.create_handler(klass)
      attributes = klass.columns.map(&:name)
      attributes.delete klass.primary_key
      handler = Class.new
      code_block = ""
      attributes.each do |attribute|
        code_block += %Q{
          def #{attribute}
            @target.#{attribute} rescue nil
          end
        }
      end
      handler.class_eval %Q{
        def initialize(target)
          @target = target
        end
        def [](attribute)
          @target[attribute] rescue nil
        end
        #{code_block}
      }
      handler
    end
  end

end
