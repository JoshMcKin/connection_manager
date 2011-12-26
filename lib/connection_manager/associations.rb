module ConnectionManager
  module Associations
    @defined_associations
    
    # Stores defined associtions and their options
    def defined_associations
      @defined_associations ||= {}
    end
        
    def belongs_to(*options)
      defined_associations[:belongs_to] ||= []
      defined_associations[:belongs_to] << options
      super
    end
    
    def has_many(*options)
      defined_associations[:has_many] ||= []
      defined_associations[:has_many] << options
      super
    end
    
    def has_one(*options)
      defined_associations[:has_one] ||= []
      defined_associations[:has_one] << options
      super
    end   
  end
end
