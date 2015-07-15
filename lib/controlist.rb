require "controlist/version"
require "controlist/errors"
require "controlist/permission"
require "controlist/interceptor"
require "controlist/managers/base_manager"

module Controlist

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
      result = yield
      @permission_provider.close_skip
      result
    end

    def is_activerecord3?
      ActiveRecord::VERSION::MAJOR == 3
    end

    def debug(*args, &block)
      logger.debug *args, &block if @logger_enabled
    end

    def enable_logger
      @logger_enabled = true
    end
  end

end
