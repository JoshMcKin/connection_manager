# ConnectionManager
Improved cross-schema, replication and mutli-DMS gem for ActiveRecord.

## Features
  * Threadsafe connection switching
  * Replication can be defined in the database.yml or in the model, adds #slaves and #masters as ActiveRecord::Relations.
  * Automatically builds connection classes, if configured.

## Installation

ConnectionManager is available through [Rubygems](https://rubygems.org/gems/connection_manager) and can be installed via:

    $ gem install connection_manager

## Rails 3/4 setup

Add connection_manager to you gemfile:
    
    gem 'connection_manager'

Run bundle install:
    
    bundle install

### Example database.yml

    common: &common
    adapter: mysql2
    pool: 20
    reconnect: true
    socket: /tmp/mysql.sock
  
    production:
      <<: *common
      database: myapp
      host: <%=ENV['DB_HOST']%>
      username: <%=ENV['DB_USER']%>
      password: <%=ENV['DB_PASS']%>
      slaves: [slave_1_production, slave_2_production]   
      build_connection_class: true

    slave_1_production:
      <<: *common
      host: <%=ENV['SLAVE_1_DB_HOST']%>
      username: <%=ENV['SLAVE_1_DB_USER']%>
      password: <%=ENV['SLAVE_1_DB_PASS']%>
      database: myapp
      build_connection_class: true

    slave_2_production:
      <<: *common
     host: <%=ENV['SLAVE_2_DB_HOST']%>
      username: <%=ENV['SLAVE_2_DB_USER']%>
      password: <%=ENV['SLAVE_2_DB_PASS']%>
      database: myapp
      build_connection_class: true

    foo_data_production
      <<: *common
      host: <%=ENV['USER_DATA_DB_HOST']%>
      username: <%=ENV['USER_DATA_DB_USER']%>
      password: <%=ENV['USER_DATA_DB_PASS']%>
      database: user_data
      build_connection_class: true

In the above database.yml the Master databases are listed as "development" and "user_data_development".
Replication databases are defined as normally connections and are added to the 'replications:' option for
their master.


## Building Connection Classes

### Manually   
ConnectionManager provides establish_managed_connection for build connection 
classes and connection to multiple databases.

    class MySlaveConnection < ActiveRecord::Base
      establish_managed_connection("slave_1_#{Rails.env}")
    end
    
    class User < MySlaveConnection;end
    
    MyConnection    => MyConnection(abstract)
    @user = User.first
    @user

The establish_managed_connection method, runs establish_connection with the supplied
database.yml key, sets abstract_class to true.
    
### Automatically   
ActiveRecord can build all your connection classes for you. 
The connection class names will be based on the database.yml keys.ActiveRecord will
build connection classes for all the entries in the database.yml where 
"build_connection_class" is true, and match the current environment settings

    # Class names derived from YML keys
    'production'           = 'BaseConnection'
    'slave_1_production'   = 'Save1Connection'
    'slave_2_production'   = 'Save2Connection'
    'foo_data_production'  = 'FooDataConnection'


## Using 

The using method allows you specify the connection class to use
for query. 
    
    User.using("Slave1Connection").first

    search = User.where(disabled => true)
    @legacy_users = search.using("Slave1Connection").all #=> [<User...>,<User...>]
    @legacy_users.first.save #=> uses the SlaveConnection connection

    @new_users = search.page(params[:page]).all => [<User...>,<User...>]

## Replication

ConnectionManager creates ActiveRecord::Relation methods :slaves and :masters.

If you specify your replication model in your database.yml there is nothing more you need to do. If you looking for more
granular control you describe the replication setup on a per-model level.
    
    class User < UserDataConnection
        has_one :job
        has_many :teams
        replicated :slaves => [MySlave1Connection, MySlave2Connection]
    end

    User.limit(2).slaves.all # => [<User...>,<User...>] results from MySlave1Connection or MySlave2Connection 


If there are multiple replication connections the system will pick a connection at random using Array#sample.
    
    User.slaves.first  => returns results from slave_1_use_data_development 
    User.slaves.last => returns results from slave_2_user_data_development  
    User.slaves.where('id BETWEEN ? and ?',1,100]).all  => returns results from slave_1_user_data_development 
    User.slaves.where('id BETWEEN ? and ?',1,100]).all  => returns results from slave_2_user_data_development 

### Repliation with cross-schema queries
Setup replication as you would normally

Next build connection classes that inherit from you base connection classes for each of your schemas
EX
    class UserSchema < ActiveRecord::Base
      self.abstract_class = true
      self.table_name_prefix = 'user_schema.'

      def self.inherited(base)
        base.use_schema(self.schema_name)
      end
    end

    class User < UserSchema
      has_many :bars
    end

    class FooSchema < ActiveRecord::Base
      self.abstract_class = true
      self.table_name_prefix = 'foo.'

      def self.inherited(base)
        base.use_schema(self.schema_name)
      end
    end

    class Bar < FooSchema
      belongs_to :user
    end

    User.joins(:bars).limit(1).to_sql # => SELECT * FROM `user_schema`.`users` INNER JOIN `foo.bars` ON `foo.bars`.`user_id` = `user_schema`.`users` LIMIT 1"

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

## Caching

ActiveRecord only caches queries for the ActiveRecord::Base connection. In order to cache queries that
originate from classes that used establish_connection you must surround your code with a cache block:

    MyOtherConnectionClass.cache {
      Some queries...
    }

In Rails, you can create an around filter for your controllers

    class ApplicationController < ActionController::Base
      around_filter :cache_slaves
      private
      def cache_slaves
        MyOnlySlaveConnection.cache { yield }
      end

## Migrations
There are lots of potential solutions [here] (http://stackoverflow.com/questions/1404620/using-rails-migration-on-different-database-than-standard-production-or-devel)

## TODOs
* Maybe add migration support for Rails AR implementations.

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