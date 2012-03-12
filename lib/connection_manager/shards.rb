module ConnectionManager
  module Shards 
    
    def shard_models(*shard_models)
      @shard_models = shard_models
    end
       
    def shards
      ConnectionManager::MethodRecorder.new((@shard_models || []))
    end  
  end
end
