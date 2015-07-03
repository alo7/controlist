require 'test_helper'

include Controlist::Permissions

class FeatureTest < ActiveSupport::TestCase

  def setup
    if Controlist.is_activerecord3?
      Controlist.skip do
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
    Controlist.permission_provider.set_permission_package(OrderedPackage.new(
      Controlist::Permission.new(User, READ, true, [
        SimpleConstrain.new("name", "Tom"),
        AdvancedConstrain.new(property: "name", value: ["Grade 1", "Grade 2"], relation: "clazz"),
        AdvancedConstrain.new(property: "age", value: 5, operator: ">="),
        SimpleConstrain.new("age", "null"),
        SimpleConstrain.new("age", [1,2,3]),
        SimpleConstrain.new("clazz_id", -> { Clazz.select(:id).map(&:id) }),
        AdvancedConstrain.new(clause: "age != 100"),
        Controlist.is_activerecord3? ?  nil : AdvancedConstrain.new(proc_read: lambda{|relation| relation.order("id DESC").limit(3) })
      ])))

    relation = User.unscoped
    relation.to_sql
    assert_equal [:clazz], relation.joins_values
    assert_equal ["(users.name = 'Tom') and (clazzs.name in ('Grade 1','Grade 2'))" +
                  " and (users.age >= 5) and (users.age is null) and (users.age in (1,2,3))" +
                  " and (users.clazz_id in (1,2)) and (age != 100)"], relation.where_values
    unless Controlist.is_activerecord3?
      assert_equal 3, relation.limit_value
      assert_equal ["id DESC"], relation.order_values
    end
  end

  def test_permission_empty
    Controlist.permission_provider.set_permission_package(nil)
    relation = User.unscoped
    relation.to_sql
    assert_equal ["1 != 1"], relation.where_values
  end

  def test_read_constrains_sql_only
    Controlist.permission_provider.set_permission_package(OrderedPackage.new(
      Controlist::Permission.new(User, READ, true, "age != 100")
    ))
    relation = User.unscoped
    relation.to_sql
    assert_equal ["age != 100"], relation.where_values
  end


  def test_read_apply_properties
    Controlist.permission_provider.set_permission_package(OrderedPackage.new(
      Controlist::Permission.new(User, READ).apply(:name)
    ))

    relation = User.unscoped
    assert_nil relation.first._value_object.clazz_id
    assert_nil relation.first._val(:clazz_id)
    assert_raise(ActiveModel::MissingAttributeError) { assert_nil relation.first.clazz_id }
    Controlist.permission_provider.set_permission_package(OrderedPackage.new(
      Controlist::Permission.new(User, READ)
    ))

    relation = User.unscoped
    assert_not_nil relation.first._value_object.clazz_id
    assert_not_nil relation.first._val(:clazz_id)
    assert_not_nil relation.first.clazz_id
  end

  def test_update_fail_without_permissions
    Controlist.permission_provider.set_permission_package(OrderedPackage.new(
      Controlist::Permission.new(User, READ)
    ))
    user = User.find 1
    assert_raise(Controlist::NoPermissionError) {
      user.name = "Test"
      user.save
    }
  end

  def test_persistence_constrains
    Controlist.permission_provider.set_permission_package(OrderedPackage.new(
      Controlist::Permission.new(Clazz, READ),
      Controlist::Permission.new(User, READ),
      Controlist::Permission.new(User, UPDATE, false, AdvancedConstrain.new(property: "name", value: "To", operator: "include?")),
      Controlist.is_activerecord3? ?  nil : Controlist::Permission.new(User, UPDATE, false, AdvancedConstrain.new(proc_persistence: lambda{|object, operation| object.name == "Block"})),
      Controlist::Permission.new(User, [UPDATE, DELETE], false, AdvancedConstrain.new(property: "name", value: "Grade 1", relation: "clazz")),
      Controlist::Permission.new(User, UPDATE)
    ))

    user = User.find 3
    assert_not_equal "Tom", user.name
    assert_not_equal "Grade 1", user.clazz.name
    user.name = "Test"
    assert_equal true, user.save

    unless Controlist.is_activerecord3?
      assert_raise(Controlist::PermissionForbidden) {
        user.name = "Block"
        user.save
      }
    end

    assert_raise(Controlist::NoPermissionError) {
      user.destroy
    }

    Controlist.permission_provider.get_permission_package.add_permissions(Controlist::Permission.new(User, DELETE))
    assert_instance_of User, user.destroy

    assert_raise(Controlist::PermissionForbidden) {
      user = User.find 1
      assert_equal "Tom", user.name
      user.name = "Test"
      user.save
    }

    assert_raise(Controlist::PermissionForbidden) {
      user = User.find 2
      assert_equal "Grade 1", user.clazz.name
      user.name = "Test"
      user.save
    }

    assert_raise(Controlist::PermissionForbidden) {
      user = User.find 2
      assert_equal "Grade 1", user.clazz.name
      user.delete
    }

  end

  def test_persistence_apply_properties
    Controlist.permission_provider.set_permission_package(OrderedPackage.new(
      Controlist::Permission.new(User, READ),
      Controlist::Permission.new(User, UPDATE, true, SimpleConstrain.new("name", "Tom")).apply(name: "Test", clazz_id: [1, 2]),
    ))

    assert_raise(Controlist::NoPermissionError) {
      user = User.find 2
      assert_not_equal "Tom", user.name
      user.name = "Test"
      user.save
    }

    assert_raise(Controlist::NoPermissionError) {
      user = User.find 1
      assert_equal "Tom", user.name
      user.name = "Jerry"
      user.save
    }

    user = User.find 1
    assert_equal "Tom", user.name
    user.clazz_id = 2
    assert_equal true, user.save
    assert_raise(Controlist::NoPermissionError) {
      user.clazz_id = 3
      user.save
    }

    user = User.find 1
    assert_equal "Tom", user.name
    user.name = "Test"
    assert_equal true, user.save

  end

  def test_modify_permissions_on_the_fly
    Controlist.permission_provider.set_permission_package(OrderedPackage.new(
      Controlist::Permission.new(User, READ),
    ))

    assert_instance_of User, User.find(1)

    package = Controlist.permission_provider.get_permission_package
    package.remove_permissions package.permissions.last

    assert_raise(ActiveRecord::RecordNotFound) {
      User.find 1
    }

    package.add_permissions Controlist::Permission.new(User, READ)
    assert_instance_of User, User.find(1)
  end

  def test_constrains_argument_error
    assert_raise(ArgumentError) {
      Controlist.permission_provider.set_permission_package(OrderedPackage.new(
        Controlist::Permission.new(User, READ, true, Object.new)
      ))
    }
  end

  def test_relation_not_reuseable
    assert_raise(Controlist::NotReuseableError) {
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
    Controlist.permission_provider.set_permission_package(OrderedPackage.new(
      Controlist::Permission.new(User, READ, true, "age != 100")
    ))
    Controlist.skip do
      relation = User.unscoped
      relation.to_sql
      assert_equal [], relation.where_values
    end
  end

end
