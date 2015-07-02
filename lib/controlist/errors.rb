module Controlist

  class ControlistError < StandardError
  end

  class NoPermissionError < ControlistError
  end

  class PermissionForbidden < ControlistError
    attr_reader :permission

    def initialize(message, permission = nil)
      @permission = permission
      super(message)
    end
  end

  class NotReuseableError < ControlistError
    attr_reader :relation
    def initialize(message, relation = nil)
      @relation = relation
      super(message)
    end
  end

end
