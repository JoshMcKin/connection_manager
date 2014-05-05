require 'active_support/core_ext/module/delegation'
module ConnectionManager
  module Querying
    delegate :using, :to => (ActiveRecord::VERSION::MAJOR == 4 ? :all : :scoped)
    delegate :slaves, :to => (ActiveRecord::VERSION::MAJOR == 4 ? :all : :scoped)
    delegate :masters, :to => (ActiveRecord::VERSION::MAJOR == 4 ? :all : :scoped)
  end
end
if ActiveRecord::VERSION::MAJOR == 4
  ActiveRecord::Querying.send(:include, ConnectionManager::Querying)
else
  ActiveRecord::Base.send(:extend, ConnectionManager::Querying)
end
