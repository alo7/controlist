require "shrike/version"
require "shrike/permission"
require "shrike/handler"

module Shrike


  def self.initialize(permission_provider)
    @permission_provider = permission_provider
    Handler.handle
  end

  def self.permission_provider
    @permission_provider
  end

end
