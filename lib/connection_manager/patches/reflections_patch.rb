if ActiveRecord::VERSION::MAJOR == 4 && ActiveRecord::VERSION::MINOR <= 0
  # Sometimes for some reason the quoted_table_name  instance methods
  # drops the schema. If the quoted table name does not include a '.'
  # want to retrieve the quoted_table_name from the class and reset
  module ActiveRecord
    # = Active Record Reflection
    module Reflection # :nodoc:
      class AssociationReflection < MacroReflection
        def table_name
          @table_name = klass.table_name
        end

        def quoted_table_name
          @quoted_table_name = klass.quoted_table_name
        end
      end
    end
  end
end
