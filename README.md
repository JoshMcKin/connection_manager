# ConnectionManager
Multi-Database and Replication and Sharding add on for ActiveRecord.

## Background
ActiveRecord, for quite some time now, has supported multiple database connections 
through the use of #establish_connection and connection classes [more info](http://api.rubyonrails.org/classes/ActiveRecord/Base.html)
Multiple databases, replication and shards can be implemented directly in rails without
patching, but a gem helps to reduce redundant code and ensure consistency. 
ConnectionManager replaces all the connection classes and subclasses required 
for multiple database support in Rails with a few class methods and simple 
database.yml configuration. Since ConnectionManager does not alter
ActiveRecord's connection pool, thread safety is not a concern.

## Upgrading to 0.3

0.3 is a complete overhaul and will cause compatibility issues for folks who upgrade using the previous replication setup.
Fortunately, for most folks the only change they have to do is specify the their slaves
and masters in the database.yml and set build_connection_class to true to have
ActiveRecord build their connection classes. See the example database.yml below.

## Installation

ConnectionManager is available through [Rubygems](https://rubygems.org/gems/connection_manager) and can be installed via:

    $ gem install connection_manager

## Rails 3 setup (No Rails 2 at this time)

Add connection_manager to you gemfile:
    
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
    build_connection_class: true
  
    development:
      <<: *common
      database: test_app
      slaves: [slave_1_test_app_development, slave_2_test_app_development]

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
      slaves: [slave_1_user_data_development, slave_2_user_data_development]

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


## Building Connection Classes

### Manually   
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


### Automatically   
ActiveRecord can build all your connection classes for you. 
The connection class names will be based on the database.yml keys.ActiveRecord will
build connection classes for all the entries in the database.yml where 
"build_connection_class" is true, and match the current environment settings

## Using 

The using method allows you specify the connection class to use
for query. The return objects will have the correct model name, but the instance's
class's superclass will be the connection class and all database actions performed 
on the instance will use the connection class's connection.
    
    User.using("Slave1Connection").first

    search = User.where(disabled => true)
    @legacy_users = search.using("Shard1Connection").all #=> [<User::Shard1ConnectionDup...>,<User::Shard1ConnectionDup..]
    @legacy_users.first.save #=> uses the Shard1Connection connection

    @new_users = search.page(params[:page]).all => [<User...>,<User...>]

## Replication

Simply add 'replicated' to your model.
    
    class User < UserDataConnection
        has_one :job
        has_many :teams
        replicated # implement replication        
        # model code ...
    end

The replicated method builds models who inherit from the main model.
    User::Slave1UserDataConnectionDup.superclass => Slave1UserDataConnection(abstract)
    User::Slave1UserDataDup.first => returns results from slave_1_user_data_development 
    User::Slave2UserDataDup.where(['created_at BETWEEN ? and ?',Time.now - 3.hours, Time.now]).all => returns results from slave_2_user_data_development

Finally, ConnectionManager creates an additional class method that shifts through your 
available slave connections each time it is called using a different connection on each action.
    
    User.slaves.first  => returns results from slave_1_use_data_development 
    User.slaves.last =>  => returns results from slave_2_use_data_development 
    User.slaves.where(['created_at BETWEEN ? and ?',Time.now - 3.hours, Time.now]).all  => returns results from slave_1_user_data_development 
    User.slaves.where(['created_at BETWEEN ? and ?',Time.now - 5.days, Time.now]).all  => returns results from slave_2_user_data_development 

Replicated defaults to the slaves replication type,so if you have only masters and a combination
of masters and slaves for replication, you have set the replication type to masters

   class User < UserDataConnection
        replicated #slaves replication
        replicated :type => :masters, :name => 'masters' # masters replication
    end

## Sharding

After tinkering with some solutions for shards, I've come to a similar conclusion as [DataFabric] (https://github.com/mperham/data_fabric):
"Sharding should be implemented at the application level". The #shards method is very basic and
while it may be useful to most folks, it should really serve as an example of a possible solutions
to your shard requirements.

    class LegacyUser < UserShardConnection
    end

    class User < ActiveRecord::Base
        self.shard_class_names = ["LegacyUser"]
    end

    # Calls the supplied block on all the shards available to User, including the User model itself.
    User.shards{ |shard| shard.where(:user_name => "some_user").all} => [<User ...>,<LegacyUser ...>]

## Migrations

Nothing implement now to help but there are lots of potential solutions [here](http://stackoverflow.com/questions/1404620/using-rails-migration-on-different-database-than-standard-production-or-devel

## TODOs
* Maybe add migration extra migration support for Rail AR implementations.

## Other ActiveRecord Connection gems
* [DataFabric] (https://github.com/mperham/data_fabric)
* [Octopus](https://github.com/tchandy/octopus)

## Contributing to ConnectionManager
 
* Check out the latest master to make sure the feature has not been implemented or the bug hasn't been fixed yet
* Check out the issue tracker to make sure someone already has not requested it and/or contributed it
* Fork the project
* Start a feature/bugfix branch
* Commit and push until you are happy with your contribution
* Make sure to add tests for it. This is important so I don't break it in a future version unintentionally.
* Please try not to mess with the Rakefile, version, or history. If you want to have your own version, or is otherwise necessary, that is fine, but please isolate to its own commit so I can cherry-pick around it.