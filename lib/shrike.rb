require "shrike/version"
require "shrike/permission"
require "shrike/handler"

module Shrike

  def self.handle(*models)
    Handler.handle *models
  end

end
