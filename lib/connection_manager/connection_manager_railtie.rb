module ConnectionManager
  class ConnectionManagerRailtie < ::Rails::Railtie
    initializer "connection_manager.build_connection_classes" do
      ActiveRecord::Base.build_connection_classes
    end
  end
end

