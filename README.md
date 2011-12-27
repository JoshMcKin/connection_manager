# ConnectionManager
Replication and Multi-Database ActiveRecord add on.

## Goals
* Take the lib I've been using finally make something out of it ;)
* Use connection classes, instead of establish_connection on every model, to ensure connection pooling
* Use non-adapter specific code.
* Use the default database.yml as single point for all database configurations (no extra .yml files)
* When slave objects are used in html helpers like link_to and form_for the created urls match those created using a master object

## Installation

ConnectionManager is available through [Rubygems](https://rubygems.org/gems/connection_manager) and can be installed via:

    $ gem install connection_manager

## Rails 3 setup (No Rails 2 at this time)

ConnectionManager assumes the primary connection for the model is the master. For standard
models using the default connection this means the main Rails database connection is the master.

Example database.yml

    common: &common
    adapter: mysql2
    username: root
    password: *****
    database_timezone: local
    pool: 100
    connect_timeout: 20
    timeout: 900
    socket: /tmp/mysql.sock
  
    development:
      <<: *common
      database: test_app

    slave_1_test_app_development:
      <<: *common
      database: test_app
  
    slave_2_test_app_development:
      <<: *common
      database: test_app

    user_data_development
      <<: *common
      database: user_data

    slave_1_user_data_development
      <<: *common
      database: user_data

    slave_2_user_data_development
      <<: *common
      database: user_data

In the above database.yml the Master databases are listed as "development" and "user_data_development".
As you can see the replication database name follow a strict standard for the connection names. 
For slave_1_test_app_development, "slave" is the name of the replication, "1" is the count, "test_app"
is the databases name and finally the "development" is the environment. (Of course in your database.yml
each slave would have a different connection to is replication :)


## Multiple Databases

At startup ConnectionManager builds connection classes  to ConnectionManager::Connections
using the connections described in your database.yml based on the current rails environment.

You can use a different master by having the model inherit from one of your ConnectionManager::Connections.

To view your ConnectionManager::Connections, at the Rails console type:

   ConnectionManager::Connections.all => ["TestAppConnection", "Slave1TestAppConnection", "Slave2TestAppConnection"]

If your using the example database.yml your array would look like this:
    ["TestAppConnection", "Slave1TestAppConnection", "Slave2TestAppConnection", 
    "UserDataConnection", "Slave1UserDataConnection", "Slave2UserDataConnection"]


To use one of your ConnectionManager::Connections for your models default/master database
setup your model like the following
    
    class User < ConnectionManager::Connections::UserDataConnection
        # model code ...
    end

## Replication

Simply add 'replicated' to your model beneath any defined associations
    
    class User < ConnectionManager::Connections::UserDataConnection
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