require "connection_manager/version"
require 'thread_safe'
require 'active_record'
require 'active_support'
require 'connection_manager/connection_adapters/abstract_adapter'
require 'connection_manager/core'
require 'connection_manager/connection_handling'
require 'connection_manager/relation'
require 'connection_manager/querying'
require 'connection_manager/builder'
require 'connection_manager/using'
require 'connection_manager/replication'
require 'connection_manager/shards'
require 'connection_manager/railtie' if defined?(Rails)

module ConnectionManager
  # Get the current environment if defined
  # Check for Rails, check for RACK_ENV, default to 'development'
  def self.env
    return @env if @env
    return Rails.env if defined?(Rails)
    return RACK_ENV if defined?(RACK_ENV)
    return ENV["AR_ENV"] if ENV["AR_ENV"]
    "development"
  end

  def self.env=env
    @env=env
  end

  def self.logger
    @logger ||= ActiveRecord::Base.logger
  end

  def self.logger=logger
    @logger = logger
  end
end
