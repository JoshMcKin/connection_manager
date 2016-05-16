require 'active_support/core_ext/module/delegation'
module ConnectionManager
  module Querying
    delegate :using, :to =>  :all
    delegate :slaves, :to =>  :all
    delegate :masters, :to => :all
  end
end
ActiveRecord::Querying.send(:include, ConnectionManager::Querying)
