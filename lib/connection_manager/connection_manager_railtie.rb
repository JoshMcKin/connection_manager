module ConnectionManager
  class ConnectionManagerRailtie < ::Rails::Railtie
    initializer "connection_manager.setup" do |app|
      
      ConnectionManager::Connections.initialize  
      require 'connection_manager/connections' 
    end
  end
end