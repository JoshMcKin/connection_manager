module ConnectionManager
  module Core
    # We want to make sure we get the full table name with schema
    def arel_table_with_check_name # :nodoc:
      @arel_table = Arel::Table.new(table_name, arel_engine) unless (@arel_table && (@arel_table.name == self.table_name))
      @arel_table
    end

    def self.included(base)
      base.alias_method_chain :arel_table, :check_name
    end

    def self.extended(base)
      class << base
        self.alias_method_chain :arel_table, :check_name
      end
    end
  end
end
ActiveRecord::Core::ClassMethods.send(:include,ConnectionManager::Core)
