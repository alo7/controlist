require 'test_helper'

include Shrike::Permissions

class FeatureTest < ActiveSupport::TestCase

  def setup
    if Shrike.is_activerecord3?
      Shrike.skip do
        load "test/migrate.rb"
        Clazz.create id: 1, name: "Grade 1"
        Clazz.create id: 2, name: "Grade 2"
        User.create id: 1, name: "Tom", clazz_id: 1, age: 1
        User.create id: 2, name: "Jerry", clazz_id: 1, age: 1
        User.create id: 3, name: "Henry", clazz_id: 2, age: 1
        User.create id: 4, name: "Tom", clazz_id: 2, age: 7
        User.create id: 5, name: "MAF", clazz_id: 2, age: 1
      end
    end
  end

  def test_read_constrains
    Shrike.permission_provider.set_permission_package(OrderedPackage.new(
      Shrike::Permission.new(User, READ, true, [
        SimpleConstrain.new("name", "Tom"),
        SimpleConstrain.new("name", ["Grade 1", "Grade 2"], relation: "clazz"),
        AdvancedConstrain.new(property: "age", value: 5, operator: ">="),
        SimpleConstrain.new("age", "null"),
        SimpleConstrain.new("age", [1,2,3]),
        SimpleConstrain.new("clazz_id", -> { Clazz.select(:id).map(&:id) }),
        AdvancedConstrain.new(clause: "age != 100"),
        Shrike.is_activerecord3? ?  nil : AdvancedConstrain.new(proc_read: lambda{|relation| relation.order("id DESC").limit(3) })
      ])))

    relation = User.unscoped
    relation.to_sql
    assert_equal [:clazz], relation.joins_values
    assert_equal ["(users.name = 'Tom') and (clazzs.name in ('Grade 1','Grade 2'))" +
                  " and (users.age >= 5) and (users.age is null) and (users.age in (1,2,3))" +
                  " and (users.clazz_id in (1,2)) and (age != 100)"], relation.where_values
    unless Shrike.is_activerecord3?
      assert_equal 3, relation.limit_value
      assert_equal ["id DESC"], relation.order_values
    end
  end

  def test_permission_empty
    Shrike.permission_provider.set_permission_package(nil)
    relation = User.unscoped
    relation.to_sql
    assert_equal ["1 != 1"], relation.where_values
  end

  def test_read_constrains_sql_only
    Shrike.permission_provider.set_permission_package(OrderedPackage.new(
      Shrike::Permission.new(User, READ, true, "age != 100")
    ))
    relation = User.unscoped
    relation.to_sql
    assert_equal ["age != 100"], relation.where_values
  end


  def test_read_apply_properties
    Shrike.permission_provider.set_permission_package(OrderedPackage.new(
      Shrike::Permission.new(User, READ).apply(:name)
    ))

    relation = User.unscoped
    assert_nil relation.first._value_object.clazz_id
    assert_nil relation.first._val(:clazz_id)
    assert_raise(ActiveModel::MissingAttributeError) { assert_nil relation.first.clazz_id }
    Shrike.permission_provider.set_permission_package(OrderedPackage.new(
      Shrike::Permission.new(User, READ)
    ))

    relation = User.unscoped
    assert_not_nil relation.first._value_object.clazz_id
    assert_not_nil relation.first._val(:clazz_id)
    assert_not_nil relation.first.clazz_id
  end

  def test_update_fail_without_permissions
    Shrike.permission_provider.set_permission_package(OrderedPackage.new(
      Shrike::Permission.new(User, READ)
    ))
    user = User.find 1
    assert_raise(Shrike::NoPermissionError) {
      user.name = "Test"
      user.save
    }
  end

  def test_persistence_constrains
    Shrike.permission_provider.set_permission_package(OrderedPackage.new(
      Shrike::Permission.new(Clazz, READ),
      Shrike::Permission.new(User, READ),
      Shrike::Permission.new(User, UPDATE, false, AdvancedConstrain.new(property: "name", value: "To", operator: "include?")),
      Shrike.is_activerecord3? ?  nil : Shrike::Permission.new(User, UPDATE, false, AdvancedConstrain.new(proc_persistence: lambda{|object, operation| object.name == 'Block'})),
      Shrike::Permission.new(User, [UPDATE, DELETE], false, SimpleConstrain.new("name", "Grade 1", relation: 'clazz')),
      Shrike::Permission.new(User, UPDATE)
    ))

    user = User.find 3
    assert_not_equal "Tom", user.name
    assert_not_equal "Grade 1", user.clazz.name
    user.name = 'Test'
    assert_equal true, user.save

    unless Shrike.is_activerecord3?
      assert_raise(Shrike::PermissionForbidden) {
        user.name = "Block"
        user.save
      }
    end

    assert_raise(Shrike::NoPermissionError) {
      user.destroy
    }

    Shrike.permission_provider.get_permission_package.add_permissions(Shrike::Permission.new(User, DELETE))
    assert_instance_of User, user.destroy

    assert_raise(Shrike::PermissionForbidden) {
      user = User.find 1
      assert_equal "Tom", user.name
      user.name = "Test"
      user.save
    }

    assert_raise(Shrike::PermissionForbidden) {
      user = User.find 2
      assert_equal "Grade 1", user.clazz.name
      user.name = "Test"
      user.save
    }

    assert_raise(Shrike::PermissionForbidden) {
      user = User.find 2
      assert_equal "Grade 1", user.clazz.name
      user.delete
    }

  end

  def test_persistence_apply_properties
    Shrike.permission_provider.set_permission_package(OrderedPackage.new(
      Shrike::Permission.new(User, READ),
      Shrike::Permission.new(User, UPDATE, true, SimpleConstrain.new("name", "Tom")).apply(name: "Test", clazz_id: [1, 2]),
    ))

    assert_raise(Shrike::NoPermissionError) {
      user = User.find 2
      assert_not_equal "Tom", user.name
      user.name = "Test"
      user.save
    }

    assert_raise(Shrike::NoPermissionError) {
      user = User.find 1
      assert_equal "Tom", user.name
      user.name = "Jerry"
      user.save
    }

    user = User.find 1
    assert_equal "Tom", user.name
    user.clazz_id = 2
    assert_equal true, user.save
    assert_raise(Shrike::NoPermissionError) {
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
      Shrike::Permission.new(User, READ),
    ))

    assert_instance_of User, User.find(1)

    package = Shrike.permission_provider.get_permission_package
    package.remove_permissions package.permissions.last

    assert_raise(ActiveRecord::RecordNotFound) {
      User.find 1
    }

    package.add_permissions Shrike::Permission.new(User, READ)
    assert_instance_of User, User.find(1)
  end

  def test_constrains_argument_error
    assert_raise(ArgumentError) {
      Shrike.permission_provider.set_permission_package(OrderedPackage.new(
        Shrike::Permission.new(User, READ, true, Object.new)
      ))
    }
  end

  def test_relation_not_reuseable
    assert_raise(Shrike::NotReuseableError) {
      relation = User.unscoped
      relation.to_sql
      relation_new = relation.where("1 = 1")
      relation_new.to_sql
    }
    relation = User.unscoped
    reuseable_relation = relation.clone
    relation.to_sql
    relation_new = reuseable_relation.where("1 = 1")
    relation_new.to_sql
  end

  def test_skip
    Shrike.permission_provider.set_permission_package(OrderedPackage.new(
      Shrike::Permission.new(User, READ, true, "age != 100")
    ))
    Shrike.skip do
      relation = User.unscoped
      relation.to_sql
      assert_equal [], relation.where_values
    end
  end

end
