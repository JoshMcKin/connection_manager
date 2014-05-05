ENV["AR_ENV"] ="test"
require 'connection_manager'
require 'rspec'
require 'bundler/setup'
require 'active_record'
require 'active_support'
require 'logger'
require 'factory_girl'
require 'helpers/database_spec_helper'

TestDB.connect#(true)
TestMigrations.down
TestMigrations.up
FactoryGirl.find_definitions
RSpec.configure do |config|
  config.mock_with :mocha
  # Loads database.yml and establishes primary connection
  # Create tables when tests are completed
  config.before(:suite) {
    require 'helpers/models_spec_helper.rb'
    ConnectionManager::Builder.build_connection_classes(TestDB.yml.select{ |k,v| v['build_connection_class'] && k.match(ConnectionManager::Builder.env_regex)}.keys)
  }
  # Make sure every test is isolated.
  config.before(:each){
    ModelsHelper.models.each{|m| Object.send(:remove_const, m)}
    load 'helpers/models_spec_helper.rb'
    FactoryGirl.reload
  }
end
