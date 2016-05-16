module ConnectionManager
  class Railtie < ::Rails::Railtie
    initializer "connection_manager.build_connection_classes" do
      ConnectionManager.env = Rails.env
      ConnectionManager.logger = Rails.logger
      ConnectionManager::Builder.build_connection_classes(Rails.application.config.database_configuration.select{ |k,v| v['build_connection_class'] && k.match(ConnectionManager::Builder.env_regex)}.keys)
    end
  end
end
