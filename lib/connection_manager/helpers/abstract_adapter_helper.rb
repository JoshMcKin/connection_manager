module ConnectionManager
  module AbstractAdapterHelper
    def config
      @config
    end
    
    def readonly?
      (config[:readonly] == true)
    end 
   
    def database_name
      config[:database]
    end
   
    def slave_keys
      config[:slaves] || []
    end
   
    def master_key
      config[:master]
    end
  end
end
