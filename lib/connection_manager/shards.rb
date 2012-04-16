module ConnectionManager
  module Shards  
    @shard_class_names = []
    
    def shard_class_names(*shard_class_names)
      @shard_class_names = shard_class_names
    end 
    
    # Takes a block
    def shards
      raise ArgumentError, "shard_class_names have not been defined for #{self.class.name}" if @shard_class_names.length == 0
      if block_given?   
        results = []
        @shard_class_names.each do |s|
          results << yield(s.constantize)
        end
        return results.flatten
      else
        raise ArgumentError, 'shards method requires a block.'
      end
    end
  end
end
