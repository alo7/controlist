require "controlist/version"
require "controlist/errors"
require "controlist/permission"
require "controlist/interceptor"
require "controlist/ext/relation_proxy.rb"
require "controlist/managers/base_manager"

module Controlist

  @logger_enabled = false

  class << self

    attr_accessor :permission_manager, :attribute_proxy, :value_object_proxy, :logger

    ##
    # example:
    #       Controlist.initialize Controlist::Managers::ThreadBasedManager
    #           attribute_proxy: "_val",
    #           value_object_proxy: "_value_object",
    #           logger: Logger.new(STDOUT)
    #
    # attribute_proxy and value_object_proxy are to avoid ActiveModel::MissingAttributeError
    # due to select(attributes) according to constrains, suppose attribute_proxy is :_val,
    # value_object_proxy is :_value_object
    #       user = User.find 1
    #       user.id
    #       user._val(:attr_might_not_be_accessed)
    #       user._value_object.attr_might_not_be_accessed
    #
    def initialize(permission_manager, config={})
      @permission_manager = permission_manager
      @attribute_proxy = config[:attribute_proxy] || "_val"
      @value_object_proxy = config[:value_object_proxy] || "_value_object"
      @logger = config[:logger] || Logger.new(STDOUT)
      Interceptor.hook
    end


    ##
    #  Skip Controlist interceptor
    #
    #      Controlist.skip do
    #        relation = User.unscoped
    #        sql = relation.to_sql
    #        assert_equal "SELECT \"users\".* FROM \"users\"", sql.strip
    #      end
    def skip
      is_skip = @permission_manager.skip?
      @permission_manager.enable_skip
      result = yield
      @permission_manager.disable_skip unless is_skip
      result
    end

    def is_activerecord3?
      ActiveRecord::VERSION::MAJOR == 3
    end

    def is_activerecord5?
      ActiveRecord::VERSION::MAJOR == 5
    end

    def debug(*args, &block)
      logger.debug(*args, &block) if @logger_enabled
    end

    def enable_logger
      @logger_enabled = true
    end

    def has_permission(klass, operation)
      permission_package = @permission_manager.get_permission_package
      permission_package && permission_package.has_permission(klass, operation)
    end

  end
end
