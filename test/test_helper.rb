require 'rails'
require 'active_record'
require 'rails/test_help'
require 'minitest/autorun'
require 'minitest/unit'
require 'minitest/pride'
require 'sqlite3'
require 'shrike'
require 'models/user'
require 'models/clazz'

ROOT_PATH = File.expand_path("../..", __FILE__)

# prepare test data
`rm test/test.sqlite3`
ActiveRecord::Base.establish_connection(
  :adapter  => "sqlite3",
  :database => "test/test.sqlite3",
  :pool=>5,
  :timeout=>5000)
class CreateSchema < ActiveRecord::Migration
  def change
    create_table :users do |t|
      t.string :name
      t.integer :clazz_id
    end
    create_table :clazzs do |t|
      t.string :name
    end
  end
end
CreateSchema.new.change

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

TEST_PERMISSIONS = {
        User => Shrike::Permission::Package.new([
          Shrike::Permission::Item.new(User, Shrike::Permission::READ, property: "name", value: "'Tom'")
              ]),
        Clazz => Shrike::Permission::Package.new([
          Shrike::Permission::Item.new(Clazz, Shrike::Permission::READ, property: "name", value: "'Grade 1'")
              ])
      }
class PermissionProvider
  class << self
    def get_permission_package(klass)
      TEST_PERMISSIONS[klass]
    end
  end
end

Shrike::Handler.permission_provider = PermissionProvider

Shrike.handle
