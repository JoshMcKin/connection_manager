# ActiveRecord 3.0 BACK PORT ONLY
# https://github.com/brianmario/mysql2/commit/14accdf8d1bf557f652c19b870316094a7441334#diff-0

if ActiveRecord::VERSION::MAJOR == 3 && ActiveRecord::VERSION::MINOR == 0
  module ActiveRecord
    module ConnectionAdapters
      class Mysql2Adapter < AbstractAdapter     
        def new_tables(database = nil) #:nodoc:
          sql = ["SHOW TABLES", database].compact.join(' IN ')
          execute(sql, 'SCHEMA').collect do |field|
            field.first
          end
        end
      
        def table_exists?(name)
          return true if super
          name          = name.to_s
          schema, table = name.split('.', 2)
          unless table # A table was provided without a schema
            table  = schema
            schema = nil
          end
          new_tables(schema).include? table
        end
      end
    end
  end
end