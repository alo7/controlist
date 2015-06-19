require 'test_helper'

include Shrike::Permission

class FeatureTest < ActiveSupport::TestCase

  def setup
  end

  def test_read_hook
   PermissionProvider.set_permission_package(Package.new(Item.new(User, READ, true, [
            {property: "name", value: "'Tom'"},
            {property: "name", value: "'Grade 1'", relation: "clazz"},
            {property: "age", value: "5", operator: ">="}
          ]))
      )
    relation = User.all
    relation.to_sql
    assert_equal [:clazz], relation.joins_values
    assert_equal ["(users.name = 'Tom') and (clazzs.name = 'Grade 1') and (users.age >= 5)"], relation.where_values
  end

end
