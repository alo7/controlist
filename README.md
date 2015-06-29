# Shrike

Fine-grained access control library for Ruby ActiveRecord

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'shrike'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install shrike

## Usage

### Initialization

```
require 'shrike'
require 'shrike/managers/thread_based_manager'
Shrike.initialize Shrike::Managers::ThreadBasedManager
```

You can use your customized manager or configuration to initialize Shrike

```
require 'shrike'
Shrike.initialize YourManager, attribute_proxy: "_val", value_object_proxy: "_value_object", logger: Logger.new(STDOUT)

```

### Feature

* support attribute level permission
* support association level permission
* attribute value check support lambda and raw sql
* persistence permistion for attribute old and new value
* persistence permistion support Proc
* modify permissions on the fly


### Example

```
Shrike.permission_provider.set_permission_package(OrderedPackage.new(
  Shrike::Permission.new(User, READ, true, [
    SimpleConstrain.new("name", "Tom"),
    SimpleConstrain.new("name", ["Grade 1", "Grade 2"], relation: "clazz"),
    AdvancedConstrain.new(property: "age", value: 5, operator: ">="),
    SimpleConstrain.new("age", "null"),
    SimpleConstrain.new("age", [1,2,3]),
    SimpleConstrain.new("clazz_id", -> { Clazz.select(:id).map(&:id) }),
    AdvancedConstrain.new(clause: "age != 100")
  ])))
relation = User.all
relation.to_sql
assert_equal [:clazz], relation.joins_values
assert_equal ["(users.name = 'Tom') and (clazzs.name in ('Grade 1','Grade 2'))" +
              " and (users.age >= 5) and (users.age is null) and (users.age in (1,2,3))" +
              " and (users.clazz_id in (1,2)) and (age != 100)"], relation.where_values
```

And more examples, please see test/feature_test.rb

## Contributing

1. Fork it ( http://git.shuobaotang.com/vw/shrike.git )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request


## License

Shrike is released under the [MIT License](http://www.opensource.org/licenses/MIT).
