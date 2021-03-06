module ConnectionManager
  module AbstractAdapter
    attr_reader :config

    # Determines if connection supports cross database queries
    def cross_schema_support?
      @cross_schema_support ||= (config[:adapter] =~ /(mysql)|(postgres)|(sqlserver)/i)
    end
    alias :cross_database_support? :cross_schema_support?

    def mysql?
      @is_mysql ||= (config[:adapter] =~ /(mysql)/i)
    end

    def postgresql?
      @is_postgresql ||= (config[:adapter] =~ /(postgres)/i)
    end

    def sqlserver?
      @is_sqlserver ||= (config[:adapter] =~ /(sqlserver)/i)
    end

    def replicated?
      (!slave_keys.blank? || !master_keys.blank?)
    end

    def database_name
      config[:database]
    end

    def slave_keys
      @slave_keys ||= (config[:slaves] ? config[:slaves].collect{|r| r.to_sym} : [] )
    end

    def master_keys
      @master_keys ||= (config[:masters] ? config[:masters].collect{|r| r.to_sym} : [])
    end

    def replication_keys(type=:slaves)
      return slave_keys if type == :slaves
      master_keys
    end

    def replications
      {:slaves => slave_keys, :masters => master_keys}
    end
  end
end
ActiveRecord::ConnectionAdapters::AbstractAdapter.send(:include,(ConnectionManager::AbstractAdapter))
