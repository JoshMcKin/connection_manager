# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require "connection_manager/version"

Gem::Specification.new do |s|
  s.name        = "connection_manager"
  s.version     = ConnectionManager::VERSION
  s.authors     = ["Joshua Mckinney"]
  s.email       = ["joshmckin@gmail.com"]
  s.homepage    = ""
  s.summary     = %q{Simplifies connecting to Muliple and Replication databases with rails and active_record}
  s.description = %q{Simplifies connecting to Muliple and Replication databases with rails and active_record}

  s.rubyforge_project = "connection_manager"

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]
  s.add_runtime_dependency 'activerecord', '~> 3.0'
  s.add_development_dependency 'rspec'
  s.add_development_dependency 'autotest'
  s.add_development_dependency 'mocha'
end
