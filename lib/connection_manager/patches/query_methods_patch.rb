module ActiveRecord
  module QueryMethods
    private
    # For some reason on .include or a custom join
    # Arel drops the table name prefix on slave classes
    def build_select(arel, selects)
      unless selects.empty?
        @implicit_readonly = false
        arel.project(*selects)
      else
        arel.project("#{quoted_table_name}.*")
      end
    end
  end
end