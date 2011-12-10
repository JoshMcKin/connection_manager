module ConnectionManager
  class ConnectionManagerRailtie < ::Rails::Railtie
    initializer "connection_manager.setup" do |app|    
      ConnectionManager::Connections.initialize  
    end
  end
end