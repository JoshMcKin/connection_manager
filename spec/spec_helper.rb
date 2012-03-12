require 'connection_manager'
require 'rspec'
require 'bundler/setup'
require 'active_record'
require 'factory_girl'
require 'helpers/database_spec_helper'

TestDB.connect('mysql2')
TestMigrations.down
TestMigrations.up
FactoryGirl.find_definitions
RSpec.configure do |config|
  config.mock_with :mocha 
  # Loads database.yml and establishes primary connection
  # Create tables when tests are completed
  config.before(:all) {
    require 'helpers/models_spec_helper'    
  }
  # Drops tables when tests are completed
  config.after(:each){
     TestDB.clean
  }
  config.after(:all){
  }
end


