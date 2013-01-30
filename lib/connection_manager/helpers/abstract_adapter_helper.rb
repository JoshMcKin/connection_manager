module ConnectionManager
  module AbstractAdapterHelper
    def config
      @config
    end
    
    # Determines if connection supports cross database queries
    def cross_database_support?
     (@config[:cross_database_support] || @config[:adapter].match(/(mysql)|(postgres)|(sqlserver)/i)) 
    end
    alias :cross_schema_support? :cross_database_support?
    
    def using_em_adapter?
      (@config[:adapter].match(/^em\_/) && defined?(EM) && EM::reactor_running?)
    end
    
    def readonly?
      (@config[:readonly] == true)
    end 
    
    def replicated?
      (!slave_keys.blank? || !master_keys.blank?)
    end
   
    def database_name
      @config[:database]
    end
   
    def replication_keys(type=:slaves)
      return slave_keys if type == :slaves
      master_keys
    end
    
    def slave_keys
      slave_keys = []
      slave_keys = @config[:slaves].collect{|r| r.to_sym} if @config[:slaves]
      slave_keys  
    end
    
    def master_keys
      master_keys = []
      master_keys = @config[:masters].collect{|r| r.to_sym} if @config[:masters]
      master_keys
    end
  end
end
