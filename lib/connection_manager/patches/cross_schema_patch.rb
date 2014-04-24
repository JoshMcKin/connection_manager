module ActiveRecord
  class Base
    class << self
      unless ActiveRecord::VERSION::MAJOR == 3 && ActiveRecord::VERSION::MINOR <= 1
        # We want to make sure we get the full table name with schema
        def arel_table # :nodoc:
          @arel_table ||= Arel::Table.new(quoted_table_name.to_s.gsub('`',''), arel_engine)
        end
      end

      private
      alias :base_compute_table_name :compute_table_name
      # In a schema schema environment we want to set table name prefix
      # to the schema_name + . if its not set already
      def compute_table_name
        result = base_compute_table_name
        if result.match(/^[^.]*$/) && connection.cross_schema_support?
          t_schema = connection.fetch_table_schema(undecorated_table_name(name))
          self.table_name_prefix = "#{t_schema}." if t_schema
          result = base_compute_table_name
        end
        result
      end
    end
  end
end

if ActiveRecord::VERSION::MAJOR == 3 && ActiveRecord::VERSION::MINOR <= 1
  require 'active_record/connection_adapters/mysql2_adapter'
  module ActiveRecord
    module ConnectionAdapters
      class Mysql2Adapter < AbstractAdapter

        # Force all tables to be cached for the life connection
        def cached_tables
          @cached_tables ||= {}
        end

        def tables(name = nil, database = nil, like =nil)
          return cached_tables[database] if cached_tables[database] && like.nil?
          cached_tables[database] ||= []
          return [like] if like && cached_tables[database].include?(like)
          sql = "SHOW TABLES "
          sql << "IN #{database} " if database
          sql << "LIKE #{quote(like)}" if like
          result = execute(sql, 'SCHEMA')
          cached_tables[database] = (cached_tables[database] | result.collect { |field| field[0] }).compact
        end

        # We have to clean the name of '`' and fetch table name with schema
        def table_exists?(name)
          return false unless name
          name          = name.to_s
          schema, table = name.split('.', 2)
          unless table # A table was provided without a schema
            table  = schema
            schema = nil
          end
          tables(nil, schema, table).include?(table)
        end
      end
    end
  end
end
