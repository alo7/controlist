require 'rails'
require 'active_record'
require 'rails/test_help'
require 'minitest/autorun'
require 'minitest/unit'
require 'minitest/pride'
require 'sqlite3'
require 'shrike'
require 'models/user'

ROOT_PATH = File.expand_path("../..", __FILE__)

# prepare test data
`rm test/test.sqlite3`
ActiveRecord::Base.establish_connection(
  :adapter  => "sqlite3",
  :database => "test/test.sqlite3",
  :pool=>5,
  :timeout=>5000)
class CreateUsers < ActiveRecord::Migration
  def change
    create_table :users do |t|
      t.string :name
    end
  end
end
CreateUsers.new.change

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

Shrike.handle User
