# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'controlist/version'

Gem::Specification.new do |spec|
  spec.name          = "controlist"
  spec.version       = Controlist::VERSION
  spec.authors       = ["Leon Li"]
  spec.email         = ["qianthinking@gmail.com"]
  spec.summary       = %q{Fine-grained access control library for Ruby ActiveRecord}
  spec.description   = %q{Use Case: RBAC (Role-Based Access Control), security for API Server and any scenario that need fine-grained or flexible access control}
  spec.homepage      = ""
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0")
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]


  spec.add_development_dependency "bundler", ">= 1.7"
  spec.add_development_dependency "rake", ">= 10.0"
  spec.add_development_dependency "minitest-rails"
  spec.add_development_dependency "minitest-reporters"
  spec.add_development_dependency "minitest"
  spec.add_development_dependency "simplecov"
  spec.add_development_dependency "sqlite3"
  if RUBY_VERSION =~ /^(1\.|2\.[01])/
    spec.add_development_dependency "activesupport", ">= 3.2.1", "< 5.0.0"
    spec.add_development_dependency "activerecord", ">= 3.2.1", "< 5.0.0"
  else
    spec.add_development_dependency "activesupport", ">= 3.2.1"
    spec.add_development_dependency "activerecord", ">= 3.2.1"
  end

  #For ActiveRecord 3 test
  #spec.add_development_dependency "minitest-rails"
  #spec.add_development_dependency "minitest-reporters"
  #spec.add_development_dependency "minitest"
  #spec.add_development_dependency "test-unit"
  #spec.add_development_dependency "simplecov", "~> 0.10.0"
  #spec.add_development_dependency "sqlite3", "~> 1.3.10"
  #spec.add_development_dependency "activesupport", "~> 3.2.1"
  #spec.add_development_dependency "activerecord", "~> 3.2.1"

end
