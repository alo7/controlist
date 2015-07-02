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

# require controlist
require 'models/user'
require 'models/clazz'
load "test/migrate.rb"

ActiveRecord::Base.logger = Logger.new(STDOUT)

require 'controlist'
require 'controlist/managers/thread_based_manager'
#Controlist.initialize Controlist::Manager::ThreadBasedManager, attribute_proxy: "_val", value_object_proxy: "_value_object", logger: Logger.new(STDOUT)
Controlist.initialize Controlist::Managers::ThreadBasedManager

unless Controlist.is_activerecord3?
  class ActiveSupport::TestCase
    ActiveRecord::Migration.check_pending!

    self.fixture_path = ROOT_PATH + "/test/fixtures"
    self.test_order = :random if self.respond_to?(:test_order=)
    fixtures :all

    # Add more helper methods to be used by all tests here...
  end
end
