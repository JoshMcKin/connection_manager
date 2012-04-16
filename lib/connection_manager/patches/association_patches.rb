if (ActiveRecord::VERSION::MAJOR == 3 && ActiveRecord::VERSION::MINOR == 0)
  ActiveRecord::Base.valid_keys_for_has_many_association << :replication_class_name
  ActiveRecord::Base.valid_keys_for_belongs_to_association << :replication_class_name
  ActiveRecord::Base.valid_keys_for_has_one_association << :replication_class_name
  ActiveRecord::Base.valid_keys_for_has_and_belongs_to_many_association << :replication_class_name
else
  module ActiveRecord::Associations::Builder
    class BelongsTo < SingularAssociation
      self.valid_options += [:replication_class_name]
    end
  end

  module ActiveRecord::Associations::Builder
    class HasMany < CollectionAssociation
      self.valid_options += [:replication_class_name]
    end
  end

  module ActiveRecord::Associations::Builder
    class HasOne < SingularAssociation
      self.valid_options += [:replication_class_name]
    end
  end

  module ActiveRecord::Associations::Builder
    class HasAndBelongsToMany < CollectionAssociation
      self.valid_options += [:replication_class_name]
    end
  end
end