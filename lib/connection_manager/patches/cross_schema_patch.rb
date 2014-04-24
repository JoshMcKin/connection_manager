# ActiveRecord 3.0 BACK PORT ONLY
# https://github.com/brianmario/mysql2/commit/14accdf8d1bf557f652c19b870316094a7441334#diff-0
# ! TODO - Refactor this mess
if ActiveRecord::VERSION::MAJOR == 3 && ActiveRecord::VERSION::MINOR <= 1
  require 'active_record/connection_adapters/mysql2_adapter'
  module ActiveRecord
    class Base
      class << self
        # We want to make sure we get the full table name with schema
        def arel_table # :nodoc:
          @arel_table ||= Arel::Table.new(quoted_table_name.to_s.gsub('`',''), arel_engine)
        end

        def quoted_table_name
          connection.quote_table_name(table_name)
        end
      end
    end
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
          (cached_tables[database] | cached_tables[database] = result.collect { |field| field[0] }).compact
        end

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

        # Make sure we always have a schema
        def quote_table_name(name)
          name = fetch_full_table_name(name)
          @quoted_table_names[name] ||= quote_column_name(name).gsub('.', '`.`')
        end

        # Try to get the schema for names missing it.
        def fetch_full_table_name(name)
          return name if (name.to_s.match(/(^$)|(\.)/))
          sql = "SELECT CONCAT(table_schema,'.',table_name) FROM INFORMATION_SCHEMA.TABLES WHERE table_name = '#{name}'"
          found = nil
          results = execute(sql, 'SCHEMA')
          found = results.to_a
          if (found.length > 1 || found.length < 1)
            found = name
          else
            found = found[0][0]
          end
          found
        end
      end
    end
  end
elsif (ActiveRecord::VERSION::MAJOR >= 3) # Rails >= 3.2
  require 'active_record/connection_adapters/abstract_mysql_adapter'
  module ActiveRecord
    module Core
      extend ActiveSupport::Concern
      module ClassMethods
        # We want to make sure we get the full table name with schema
        def arel_table # :nodoc:
          @arel_table ||= Arel::Table.new(quoted_table_name.to_s.gsub('`',''), arel_engine)
        end
      end
    end

    module ConnectionAdapters
      class AbstractMysqlAdapter < AbstractAdapter

        # Make sure we always have a schema
        def quote_table_name(name)
          name = fetch_full_table_name(name)
          @quoted_table_names[name] ||= quote_column_name(name).gsub('.', '`.`')
        end

        # We always want the table_schema.table_name if the table name is unique
        def fetch_full_table_name(name)
          return name if (name.to_s.match(/(^$)|(\.)/))
          sql = "SELECT CONCAT(table_schema,'.',table_name) FROM INFORMATION_SCHEMA.TABLES WHERE table_name = '#{name}'"
          execute_and_free(sql, 'SCHEMA') do |result|
            found = result.to_a
            return name if (found.length > 1 || found.length < 1)
            found[0][0]
          end
        end
      end
    end
  end
end
