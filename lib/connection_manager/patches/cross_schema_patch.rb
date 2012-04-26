### https://github.com/rails/rails/issues/539
### http://tamersalama.com/2010/09/27/nomethoderror-undefined-method-eq-for-nilnilclass/
### https://github.com/rails/rails/blob/3-0-stable/activerecord/lib/active_record/associations.rb
# ActiveRecord 3.0 ONLY

if ActiveRecord::VERSION::MAJOR == 3 && ActiveRecord::VERSION::MINOR == 0
  module ActiveRecord
    module ConnectionAdapters
      class Mysql2Adapter     
        def tables(name = nil, database = nil) #:nodoc:
          sql = ["SHOW TABLES", database].compact.join(' IN ')
          execute(sql, 'SCHEMA').collect do |field|
            field.first
          end
        end
      
        def table_exists?(name)
          return true if super
          name          = name.to_s
          puts name
          schema, table = name.split('.', 2)
          puts "#{schema} - #{table}"
          unless table # A table was provided without a schema
            table  = schema
            schema = nil
          end
          tables(nil, schema).include? table
        end
      end
    end
  end
end