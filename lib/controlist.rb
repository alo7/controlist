require "controlist/version"
require "controlist/errors"
require "controlist/permission"
require "controlist/interceptor"
require "controlist/managers/base_manager"

module Controlist

  class << self

    attr_accessor :permission_manager, :attribute_proxy, :value_object_proxy, :logger

    def initialize(permission_manager, config={})
      @permission_manager = permission_manager
      @attribute_proxy = config[:attribute_proxy] || "_val"
      @value_object_proxy = config[:value_object_proxy] || "_value_object"
      @logger = config[:logger] || Logger.new(STDOUT)
      Interceptor.hook
    end

    def skip
      @permission_manager.enable_skip
      result = yield
      @permission_manager.disable_skip
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
