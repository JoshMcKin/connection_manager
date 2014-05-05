# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require "connection_manager/version"

Gem::Specification.new do |s|
  s.name        = "connection_manager"
  s.version     = ConnectionManager::VERSION
  s.authors     = ["Joshua Mckinney"]
  s.email       = ["joshmckin@gmail.com"]
  s.homepage    = ""
  s.summary     = %q{Cross-schema, replication and mutli-DMS gem for ActiveRecord.}
  s.description = %q{Improves support for cross-schema, replication and mutli-DMS applications using ActiveRecord.}

  s.rubyforge_project = "connection_manager"

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]
  s.add_runtime_dependency 'activerecord', '>= 3.0', '<= 4.1'
  s.add_runtime_dependency 'activesupport', '>= 3.0', '<= 4.1'
  s.add_runtime_dependency 'thread_safe'
  s.add_development_dependency 'rspec'
  s.add_development_dependency 'autotest'
  s.add_development_dependency 'mocha'
  s.add_development_dependency 'factory_girl'
  s.add_development_dependency 'mysql2'
  s.add_development_dependency 'pg'
end