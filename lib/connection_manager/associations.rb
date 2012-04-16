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
      after_association
    end
    
    def has_one(*options)
      defined_associations[:has_one] ||= []
      defined_associations[:has_one] << options
      super
      after_association
    end
    
    def has_many(*options)
      defined_associations[:has_many] ||= []
      defined_associations[:has_many] << options
      super
      after_association
    end
    
    def has_and_belongs_to_many(*options)
      defined_associations[:has_and_belongs_to_many] ||= []
      defined_associations[:has_and_belongs_to_many] << options
      super
      after_association
    end
    
    # Hook to run code after assocation is defined
    def after_association
    end
  
  end
  
  
  
end
