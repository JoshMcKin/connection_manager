module ConnectionManager
  class Railtie < ::Rails::Railtie
    initializer "connection_manager.build_connection_classes" do
      require 'connection_manager/connection_adapters/mysql_adapter' if (ActiveRecord::VERSION::MAJOR == 3 && ActiveRecord::VERSION::MINOR <= 1 && (defined?(Mysql2::VERSION) || defined?(Mysql2::VERSION))
      ConnectionManager.env = Rails.env
      ConnectionManager.logger = Rails.logger
      ConnectionManager::Builder.build_connection_classes(Rails.application.config.database_configuration.select{ |k,v| v['build_connection_class'] && k.match(ConnectionManager::Builder.env_regex)}.keys)
    end
  end
end
