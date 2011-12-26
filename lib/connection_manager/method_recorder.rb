require 'active_record'
module ConnectionManager 
  class MethodRecorder  
    attr_accessor :classes_to_call
    
    def initialize(classes_to_call=[])
      self.classes_to_call = classes_to_call
    end
    
    # A place to store our methods and thier variables
    def recordings
      @recordings ||= {}
    end
    
    def execute_recordings
      results = []
      classes_to_call.each do |class_to_call|
        called = nil
        recordings.each do |name,args|
          args = args[0] if [Array, Hash].include?args[0].class 
          if called.nil?
            if args.blank?
              called = class_to_call.send(name.to_sym)         
            else
              called = class_to_call.send(name.to_sym, args)
            end
          else
            if args.blank?
              called = called.send(name.to_sym)
            else
              called = called.send(name.to_sym, args)
            end
          end
        end
        if called.is_a?(Array)
          results = (results | called)
        else
          results << called
        end   
      end
      results
    end
    
    # Create recorder classes for methods that might be called on a ActiveRecord
    # model in the process of building a query
    (ActiveRecord::FinderMethods.instance_methods | ActiveRecord::QueryMethods.instance_methods).each do |method|
      define_method(method) do |*args|
        recordings[method] = args 
        self
      end
    end
    
    def execute
      execute_recordings
    end
  end  
end
