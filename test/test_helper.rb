ROOT_PATH = File.expand_path("../..", __FILE__)

require 'simplecov'
SimpleCov.start do
  add_filter '/test/'
end

require 'rails'
require 'active_record'
require 'rails/test_help'
require 'minitest/autorun'
require 'minitest/unit'
require 'minitest/pride'
require "minitest/reporters"
Minitest::Reporters.use!
require 'sqlite3'

# require shrike
require 'shrike'
require 'shrike/default_permission_provider'
require 'models/user'
require 'models/clazz'
require 'migrate'

class ActiveSupport::TestCase
  ActiveRecord::Migration.check_pending!

  # Setup all fixtures in test/fixtures/*.yml for all tests in alphabetical order.
  #
  # Note: You'll currently still have to declare fixtures explicitly in integration tests
  # -- they do not yet inherit this setting

  self.fixture_path = ROOT_PATH + "/test/fixtures"
  self.test_order = :random
  fixtures :all

  # Add more helper methods to be used by all tests here...
end

ActiveRecord::Base.logger = Logger.new(STDOUT)

Shrike.initialize Shrike::DefaultPermissionProvider
