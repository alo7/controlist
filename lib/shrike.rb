require "shrike/version"
require "shrike/handler"

module Shrike

  def self.handle(*models)
    models.each do |model|
      Handler.handle model
    end
  end

end
