# Controlist

## Fine-grained access control library for Ruby ActiveRecord

Controlist support Ruby 1.9 and 2.x, ActiveRecord 3.2 and 4.1+

## Use Case

RBAC (Role-Based Access Control)
Security for API Server
Any scenario that need fine-grained or flexible access control

## Feature

* Support ActiveRecord CRUD permissions
* Support attribute level permission
* Support association level permission
* Filter attributes for READ permission
* Check changed and previous value for persistence operation
* CRUD permission support lambda, argument is "Relation" for READ or "Object" for persistence(ActiveRecord 4.1+)
* Attribute value check support lambda and raw sql
* Modify permissions on the fly
* Skip permission check on demand

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'controlist'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install controlist

## Usage

### Initialization

```ruby
require 'controlist'
require 'controlist/managers/thread_based_manager'
Controlist.initialize Controlist::Managers::ThreadBasedManager
```

You can use your customized manager or configuration to initialize Controlist

```ruby
require 'controlist'
Controlist.initialize YourManager #, attribute_proxy: "_val", value_object_proxy: "_value_object", logger: Logger.new(STDOUT)

```

## Example

```ruby
Controlist.permission_provider.set_permission_package(OrderedPackage.new(
  Controlist::Permission.new(User, READ, true, [
    SimpleConstrain.new("name", "Tom"),
    SimpleConstrain.new("name", ["Grade 1", "Grade 2"], relation: "clazz"),
    AdvancedConstrain.new(property: "age", value: 5, operator: ">="),
    SimpleConstrain.new("age", "null"),
    SimpleConstrain.new("age", [1,2,3]),
    SimpleConstrain.new("clazz_id", -> { Clazz.select(:id).map(&:id) }),
    AdvancedConstrain.new(clause: "age != 100"),
    AdvancedConstrain.new(proc_read: lambda{|relation| relation.order("id DESC").limit(3) })
  ])))
relation = User.all
relation.to_sql
assert_equal [:clazz], relation.joins_values
assert_equal ["(users.name = 'Tom') and (clazzs.name in ('Grade 1','Grade 2'))" +
              " and (users.age >= 5) and (users.age is null) and (users.age in (1,2,3))" +
              " and (users.clazz_id in (1,2)) and (age != 100)"], relation.where_values
assert_equal 3, relation.limit_value
assert_equal ["id DESC"], relation.order_values
```

And more examples, please see [more examples](https://github.com/alo7/controlist/blob/master/test/feature_test.rb)

## Contributing

1. Fork it ( https://github.com/alo7/controlist.git )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request


## License

Controlist is released under the [MIT License](http://www.opensource.org/licenses/MIT).
