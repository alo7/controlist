module Shrike

  class ShrikeError < StandardError
  end

  class NoPermissionError < ShrikeError
  end

  class PermissionForbidden < ShrikeError
    attr_reader :permission

    def initialize(message, permission = nil)
      @permission = permission
      super(message)
    end
  end

end
