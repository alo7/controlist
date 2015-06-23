require 'test_helper'

include Shrike::Permission

class FeatureTest < ActiveSupport::TestCase

  def setup
  end

  def test_read_constrains_with_join
    PermissionProvider.set_permission_package(Package.new(
      Item.new(User, READ, true, [
        {property: "name", value: "'Tom'"},
        {property: "name", value: "'Grade 1'", relation: "clazz"},
        {property: "age", value: "5", operator: ">="},
        {property: "age", value: "null"},
        {clause: "age != 100"}
      ])))
    relation = User.all
    relation.to_sql
    assert_equal [:clazz], relation.joins_values
    assert_equal ["(users.name = 'Tom') and (clazzs.name = 'Grade 1') and (users.age >= 5) and (users.age is null) and (age != 100)"],
      relation.where_values
  end

  def test_read_empty_with_permissions
    PermissionProvider.set_permission_package(nil)
    relation = User.all
    relation.to_sql
    assert_equal ["1 != 1"], relation.where_values
  end

  def test_read_constrains_sql_only
    PermissionProvider.set_permission_package(Package.new(
      Item.new(User, READ, true, "age != 100")
    ))
    relation = User.all
    relation.to_sql
    assert_equal ["age != 100"], relation.where_values
  end

  def test_read_constrains_error
    assert_raise(ArgumentError) { 
      PermissionProvider.set_permission_package(Package.new(
        Item.new(User, READ, true, Object.new)
      ))
    }
  end

end
