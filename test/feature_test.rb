require 'test_helper'

include Shrike::Permission

class FeatureTest < ActiveSupport::TestCase

  def setup
  end

  def test_read_constrains_with_join
    Shrike::DefaultPermissionProvider.set_permission_package(Package.new(
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
    Shrike::DefaultPermissionProvider.set_permission_package(nil)
    relation = User.all
    relation.to_sql
    assert_equal ["1 != 1"], relation.where_values
  end

  def test_read_constrains_sql_only
    Shrike::DefaultPermissionProvider.set_permission_package(Package.new(
      Item.new(User, READ, true, "age != 100")
    ))
    relation = User.all
    relation.to_sql
    assert_equal ["age != 100"], relation.where_values
  end

  def test_read_constrains_sql_only
    Shrike::DefaultPermissionProvider.set_permission_package(Package.new(
      Item.new(User, READ, true, "age != 100")
    ))
    Shrike.skip do
      relation = User.all
      relation.to_sql
      assert_equal [], relation.where_values
    end
  end


  def test_read_apply_properties
    Shrike::DefaultPermissionProvider.set_permission_package(Package.new(
      Item.new(User, READ).apply(:name)
    ))
    relation = User.all
    assert_nil relation.first._value_object.clazz_id
    assert_nil relation.first._val(:clazz_id)
    assert_raise(ActiveModel::MissingAttributeError) { assert_nil relation.first.clazz_id }
    Shrike::DefaultPermissionProvider.set_permission_package(Package.new(
      Item.new(User, READ)
    ))
    relation = User.all
    assert_not_nil relation.first._value_object.clazz_id
    assert_not_nil relation.first._val(:clazz_id)
    assert_not_nil relation.first.clazz_id
  end

  def test_read_constrains_error
    assert_raise(ArgumentError) {
      Shrike::DefaultPermissionProvider.set_permission_package(Package.new(
        Item.new(User, READ, true, Object.new)
      ))
    }
  end

  def test_update_fail_without_permissions
    Shrike::DefaultPermissionProvider.set_permission_package(Package.new(
      Item.new(User, READ)
    ))
    user = User.find 1
    assert_raise(PermissionError) {
      user.name = "Test"
      user.save
    }
  end

  def test_update_constrains_with_join
    Shrike::DefaultPermissionProvider.set_permission_package(Package.new(
      Item.new(User, READ),
      Item.new(User, UPDATE, false, SimpleConstrain.new("name", "Tom"))))
    user = User.find 1
    assert_raise(PermissionError) {
      user.name = "Test"
      user.save
    }
    user = User.find 2
    assert_raise(PermissionError) {
      user.name = "Test"
      user.save
    }
  end

end
