require 'test_helper'

include Shrike::Permission

class FeatureTest < ActiveSupport::TestCase

  def setup
  end

  def test_read_constrains_with_join
    PermissionProvider.set_permission_package(Package.new(
      Item.new(User, READ, true, [
        SimpleConstrain.new("name", "Tom"),
        SimpleConstrain.new("name", "Grade 1", relation: "clazz"),
        AdvancedConstrain.new(property: "age", value: "5", type: Integer, operator: ">="),
        SimpleConstrain.new("age", "null"),
        AdvancedConstrain.new(clause: "age != 100")
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

  def test_update_fail_without_permissions
    PermissionProvider.set_permission_package(Package.new(
      Item.new(User, READ)
    ))
    user = User.find 1
    assert_raise(PermissionError) {
      user.name = "Test"
      user.save
    }
  end

  def test_update_constrains_with_join
    PermissionProvider.set_permission_package(Package.new(
      Item.new(User, READ),
      Item.new(User, UPDATE, false, [
        SimpleConstrain.new("name", "Tom"),
        SimpleConstrain.new("name", "Grade 1", relation: "clazz"),
        SimpleConstrain.new("age", "null"),
      ])))
    user = User.find 1
    assert_raise(PermissionError) {
      user.name = "Test"
      user.save
    }
  end

end
