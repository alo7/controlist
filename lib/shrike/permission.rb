module Shrike
  module Permission

    CREATE = :create
    READ = :read
    UPDATE = :update
    DELETE = :delete

  end
end
require 'shrike/permission/simple_constrain'
require 'shrike/permission/advanced_constrain'
require 'shrike/permission/item'
require 'shrike/permission/Package'
