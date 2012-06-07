module ConnectionManager
  module Shards  
    @shard_class_names = []
    
    def shard_class_names(*shard_class_names)
      @shard_class_names = shard_class_names
    end 
    
    # Takes a block that is call on all available shards.
    def shards(*opts,&shards_block)
      opts = {:include_self => true}.merge(opts.extract_options!)
      raise ArgumentError, "shard_class_names have not been defined for #{self.class.name}" if @shard_class_names.length == 0
      if block_given?   
        results = []
        @shard_class_names.each do |s|
          results << shards_block.call(s.constantize)
        end
        results << shards_block.call(self) if opts[:include_self]
        return results.flatten
      else
        raise ArgumentError, 'shards method requires a block.'
      end
    end
  end
end