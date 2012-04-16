module ConnectionManager
  module AbstractAdapterHelper
    def config
      @config
    end
    
    def using_em_adapter?
      (config[:adapter].match(/^em\_/) && defined?(EM) && EM::reactor_running?)
    end
    
    def readonly?
      (config[:readonly] == true)
    end 
    
    def replicated
      !config[:replications].blank?
    end
   
    def database_name
      config[:database]
    end
   
    def replication_keys
      (config[:replications].collect{|r| r.to_sym} || [])
    end
  end
end
