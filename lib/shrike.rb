require "shrike/version"
require "shrike/errors"
require "shrike/permission"
require "shrike/interceptor"
require "shrike/managers/base_manager"

module Shrike

  class << self

    attr_accessor :permission_provider, :attribute_proxy, :value_object_proxy, :logger

    def initialize(permission_provider, config={})
      @permission_provider = permission_provider
      @attribute_proxy = config[:attribute_proxy] || "_val"
      @value_object_proxy = config[:value_object_proxy] || "_value_object"
      @logger = config[:logger] || Logger.new(STDOUT)
      Interceptor.hook
    end

    def skip
      @permission_provider.open_skip
      yield
      @permission_provider.close_skip
    end
  end

end
