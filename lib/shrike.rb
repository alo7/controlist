require "shrike/version"
require "shrike/permission_error"
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

  def self.skip
    @permission_provider.open_skip
    yield
    @permission_provider.close_skip
  end

end
