module ConnectionManager
  class ConnectionManagerRailtie < ::Rails::Railtie
    initializer "connection_manager.setup" do |app|    
      ConnectionManager::Connections.build_connection_classes  
    end
  end
end