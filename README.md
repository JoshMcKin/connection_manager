# ConnectionManager
Replication and Multi-Database ActiveRecord add on.


## Background
ActiveRecord, for quite some time now, has supported multiple database connections 
through the use of establish_connection and connection classes [more info](http://api.rubyonrails.org/classes/ActiveRecord/Base.html)
Multiple databases, replication and shards can be implemented directly in rails, but 
a gem would real help reduce redundant code and ensure consistency. 

## Installation

ConnectionManager is available through [Rubygems](https://rubygems.org/gems/connection_manager) and can be installed via:

    $ gem install connection_manager

## Rails 3 setup (No Rails 2 at this time)

Add em_aws to you gemfile:
    
    gem 'connection_manager'

Run bundle install:
    
    bundle install

### Example database.yml

    common: &common
    adapter: mysql2
    username: root
    password: *****
    pool: 20
    connect_timeout: 20
    timeout: 900
    socket: /tmp/mysql.sock
  
    development:
      <<: *common
      database: test_app
      replications: [slave_1_test_app_development, slave_2_test_app_development]

    slave_1_test_app_development:
      <<: *common
      database: test_app
      readonly: true
  
    slave_2_test_app_development:
      <<: *common
      database: test_app
      readonly: true

    user_data_development
      <<: *common
      database: user_data
      replications: [slave_1_user_data_development, slave_2_user_data_development]

    slave_1_user_data_development
      <<: *common
      database: user_data
      readonly: true

    slave_2_user_data_development
      <<: *common
      database: user_data
      readonly: true

In the above database.yml the Master databases are listed as "development" and "user_data_development".
Replication databases are defined as normally connections and are added to the 'replications:' option for
their master. The readonly option ensures all ActiveRecord objects returned from this connection are ALWAYS readonly.

### Building Connection Classes
    
ConnectionManager provides establish_managed_connection for build connection 
classes and connection to multiple databases.

    class MyConnection < ActiveRecord::Base
      establish_managed_connection("my_database_#{Rails.env}", :readonly => true)
    end
    
    class User < MyConnection
    end
    
    MyConnection    => MyConnection(abstract)
    @user = User.first
    @user.readonly? => true

The establish_managed_connection method, runs establish_connection with the supplied
database.yml key, sets abstract_class to true, and (since :readonly is set to true) ensures
all ActiveRecord objects build using this connection class are readonly. If readonly is set
to true in the database.yml, passing the readonly option is not necessary.  

You mcan build all your connections classes or you can have ConnectionManager do it for you. 
The connection class names will be based on the database.yml keys.

    # If RAKE_ENV or Rails.env == development
    # database.yml keys: development, slave_1_development, slave_2_development  

    ConnectionManager::Connections.build_connection_classes
    ActiveRecord::Base.managed_connections => ["BaseConnection", "Slave1Connection", "Slave2Connection"]

The build_connection_classes finds all the entries in the database.yml for the current environment
a builds connection classes for each.

## Replication

Simply add 'replicated' to your model beneath any defined associations
    
    class User < UserDataConnection
        has_one :job
        has_many :teams
        replicated # implement replication        
        # model code ...
    end

The replicated method addeds subclass whose names match the replication connection name and count.
Based on the above example database.yml User class would now have User::Slave1 and User::Slave2. 

You can treat your subclass like normal activerecord objects.
    
    User::Slave1.first => returns results from slave_1_user_data_development 
    User::Slave2.where(['created_at BETWEEN ? and ?',Time.now - 3.hours, Time.now]).all => returns results from slave_2_user_data_development

For a more elegant implementation, ConnectionManager also add class methods to your main model following the
same naming standard as the subclass creation.
    
    User.slave_1.first  => returns results from slave_1_user_data_development 
    User.slave_2.where(['created_at BETWEEN ? and ?',Time.now - 3.hours, Time.now]).all  => returns results from slave_2_user_data_development 

Finally, ConnectionManager creates an addional class method that shifts through your 
available slave connections each time it is called using a different connection on each action.
    
    User.slave.first  => returns results from slave_1_use_data_development 
    User.slave.last =>  => returns results from slave_2_use_data_development 
    User.slave.where(['created_at BETWEEN ? and ?',Time.now - 3.hours, Time.now]).all  => returns results from slave_1_user_data_development 
    User.slave.where(['created_at BETWEEN ? and ?',Time.now - 5.days, Time.now]).all  => returns results from slave_2_user_data_development 

## TODO's
* sharding - IN 2.0 AS BETA
* cross schema joins - 2.2 AS BETA tested with Mysql2 ONLY

## Other activerecord Connection gems
* [Octopus](https://github.com/tchandy/octopus)

## Contributing to ConnectionManager
 
* Check out the latest master to make sure the feature hasn't been implemented or the bug hasn't been fixed yet
* Check out the issue tracker to make sure someone already hasn't requested it and/or contributed it
* Fork the project
* Start a feature/bugfix branch
* Commit and push until you are happy with your contribution
* Make sure to add tests for it. This is important so I don't break it in a future version unintentionally.
* Please try not to mess with the Rakefile, version, or history. If you want to have your own version, or is otherwise necessary, that is fine, but please isolate to its own commit so I can cherry-pick around it.