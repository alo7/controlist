require 'test_helper'

include Shrike::Permission

class FeatureTest < ActiveSupport::TestCase

  def test_read_constrains_with_join
    Shrike.permission_provider.set_permission_package(OrderedPackage.new(
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

  def test_permission_empty
    Shrike.permission_provider.set_permission_package(nil)
    relation = User.all
    relation.to_sql
    assert_equal ["1 != 1"], relation.where_values
  end

  def test_read_constrains_sql_only
    Shrike.permission_provider.set_permission_package(OrderedPackage.new(
      Item.new(User, READ, true, "age != 100")
    ))
    relation = User.all
    relation.to_sql
    assert_equal ["age != 100"], relation.where_values
  end


  def test_read_apply_properties
    Shrike.permission_provider.set_permission_package(OrderedPackage.new(
      Item.new(User, READ).apply(:name)
    ))

    relation = User.all
    assert_nil relation.first._value_object.clazz_id
    assert_nil relation.first._val(:clazz_id)
    assert_raise(ActiveModel::MissingAttributeError) { assert_nil relation.first.clazz_id }
    Shrike.permission_provider.set_permission_package(OrderedPackage.new(
      Item.new(User, READ)
    ))

    relation = User.all
    assert_not_nil relation.first._value_object.clazz_id
    assert_not_nil relation.first._val(:clazz_id)
    assert_not_nil relation.first.clazz_id
  end

  def test_update_fail_without_permissions
    Shrike.permission_provider.set_permission_package(OrderedPackage.new(
      Item.new(User, READ)
    ))
    user = User.find 1
    assert_raise(PermissionError) {
      user.name = "Test"
      user.save
    }
  end

  def test_persistence_constrains
    Shrike.permission_provider.set_permission_package(OrderedPackage.new(
      Item.new(Clazz, READ),
      Item.new(User, READ),
      Item.new(User, UPDATE, false, SimpleConstrain.new("name", "Tom")),
      Item.new(User, [UPDATE, DELETE], false, SimpleConstrain.new("name", "Grade 1", relation: 'clazz')),
      Item.new(User, UPDATE)
    ))

    user = User.find 3
    assert_not_equal "Tom", user.name
    assert_not_equal "Grade 1", user.clazz.name
    user.name = 'Test'
    assert_equal true, user.save

    assert_raise(PermissionError) {
      user.destroy
    }

    Shrike.permission_provider.get_permission_package.add_permissions(Item.new(User, DELETE))
    assert_instance_of User, user.destroy

    assert_raise(PermissionError) {
      user = User.find 1
      assert_equal "Tom", user.name
      user.name = "Test"
      user.save
    }

    assert_raise(PermissionError) {
      user = User.find 2
      assert_equal "Grade 1", user.clazz.name
      user.name = "Test"
      user.save
    }

    assert_raise(PermissionError) {
      user = User.find 2
      assert_equal "Grade 1", user.clazz.name
      user.delete
    }

  end

  def test_persistence_apply_properties
    Shrike.permission_provider.set_permission_package(OrderedPackage.new(
      Item.new(User, READ),
      Item.new(User, UPDATE, true, SimpleConstrain.new("name", "Tom")).apply(name: "Test", clazz_id: [1, 2]),
    ))

    assert_raise(PermissionError) {
      user = User.find 2
      assert_not_equal "Tom", user.name
      user.name = "Test"
      user.save
    }

    assert_raise(PermissionError) {
      user = User.find 1
      assert_equal "Tom", user.name
      user.name = "Jerry"
      user.save
    }

    user = User.find 1
    assert_equal "Tom", user.name
    user.clazz_id = 2
    assert_equal true, user.save
    assert_raise(PermissionError) {
      user.clazz_id = 3
      user.save
    }

    user = User.find 1
    assert_equal "Tom", user.name
    user.name = "Test"
    assert_equal true, user.save

  end

  def test_modify_permissions_on_the_fly
    Shrike.permission_provider.set_permission_package(OrderedPackage.new(
      Item.new(User, READ),
    ))

    assert_instance_of User, User.find(1)

    package = Shrike.permission_provider.get_permission_package
    package.remove_permissions package.permissions.last

    assert_raise(ActiveRecord::RecordNotFound) {
      User.find 1
    }

    package.add_permissions Item.new(User, READ)
    assert_instance_of User, User.find(1)
  end

  def test_constrains_argument_error
    assert_raise(ArgumentError) {
      Shrike.permission_provider.set_permission_package(OrderedPackage.new(
        Item.new(User, READ, true, Object.new)
      ))
    }
  end

  def test_skip
    Shrike.permission_provider.set_permission_package(OrderedPackage.new(
      Item.new(User, READ, true, "age != 100")
    ))
    Shrike.skip do
      relation = User.all
      relation.to_sql
      assert_equal [], relation.where_values
    end
  end

end
