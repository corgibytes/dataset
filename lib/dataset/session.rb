module Dataset
  class Session # :nodoc:
    attr_accessor :dataset_resolver
    
    def initialize(database, dataset_resolver = Resolver.default)
      @database = database
      @dataset_resolver = dataset_resolver
      reset!
    end
    
    def reset!
      @datasets = Hash.new
      @load_stack = []
    end
    
    def add_dataset(test_class, dataset_identifier)
      dataset = dataset_resolver.resolve(dataset_identifier)
      if dataset.used_datasets
        dataset.used_datasets.each { |used_dataset| self.add_dataset(test_class, used_dataset) }
      end
      datasets_for(test_class) << dataset
    end
    
    def datasets_for(test_class)
      if test_class.superclass
        @datasets[test_class] ||= Collection.new(datasets_for(test_class.superclass) || [])
      end
    end
        
    def load_datasets_for(test_class, options = {:force_clear => false})
      datasets = datasets_for(test_class)
      last_load = @load_stack.last 
      unless options[:force_clear] or last_load.nil?
        if last_load.datasets == datasets
          current_load = Reload.new(last_load)
        elsif last_load.datasets.subset?(datasets)
          current_load = Load.new(datasets, last_load.dataset_binding)
          current_load.execute(last_load.datasets, @dataset_resolver)
          @load_stack.push(current_load)
        else
          # We have to clear and start over in this case, because a sibling
          # dataset was loaded before this one, and we need to wipe out any
          # state that the sibling may have created.
          
          @load_stack.pop          
          current_load = load_datasets_for(test_class, :force_clear => true)
        end
      else
        @database.clear
        current_load = Load.new(datasets, @database)
        current_load.execute([], @dataset_resolver)
        @load_stack.push(current_load)
      end

      current_load
    end
  end
end