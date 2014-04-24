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
      return @config[:slaves].collect{|r| r.to_sym} if @config[:slaves]
      []
    end

    def master_keys
      return @config[:masters].collect{|r| r.to_sym} if @config[:masters]
      []
    end

    if ActiveRecord::VERSION::MAJOR == 3 && ActiveRecord::VERSION::MINOR <= 1

      # Returns the schema for a give table. Returns nil of multiple matches are found  
      def fetch_table_schema(table_name)
        sql = "SELECT table_schema FROM INFORMATION_SCHEMA.TABLES WHERE table_name = '#{table_name}'"
        found = nil
        results = execute(sql, 'SCHEMA')
        found = results.to_a
        if (found.length == 1)
          found = found[0][0]
        end
        found
      end

      # Returns table_schema.table_name for the given table. Returns nil if multiple matches are found
      def fetch_full_table_name(table_name)
        return table_name if (table_name.to_s.match(/(^$)|(\.)/))
        sql = "SELECT CONCAT(table_schema,'.',table_name) FROM INFORMATION_SCHEMA.TABLES WHERE table_name = '#{table_name}'"
        found = nil
        results = execute(sql, 'SCHEMA')
        found = results.to_a
        if (found.length == 1)
          found = found[0][0]
        else
          found = table_name
        end
        found
      end
    else
      
      # Returns the schema for a give table. Returns nil of multiple matches are found      
      def fetch_table_schema(table_name)
        sql = "SELECT table_schema FROM INFORMATION_SCHEMA.TABLES WHERE table_name = '#{table_name}'"
        execute_and_free(sql, 'SCHEMA') do |result|
          found = result.to_a
          return nil unless (found.length == 1)
          found[0][0]
        end
      end

      # Returns table_schema.table_name for the given table. Returns nil if multiple matches are found
      def fetch_full_table_name(table_name)
        return table_name if (table_name.to_s.match(/(^$)|(\.)/))
        sql = "SELECT CONCAT(table_schema,'.',table_name) FROM INFORMATION_SCHEMA.TABLES WHERE table_name = '#{table_name}'"
        execute_and_free(sql, 'SCHEMA') do |result|
          found = result.to_a
          return table_name unless (found.length == 1)
          found[0][0]
        end
      end
    end
  end
end
