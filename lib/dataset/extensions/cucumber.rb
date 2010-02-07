$__cucumber_toplevel = self

module Dataset
  module Extensions # :nodoc:
    class CucumberInitializer # :nodoc:
      include Dataset
      
      def load(*datasets)
        datasets.each do |dataset|          
          self.class.add_dataset(dataset)
        end

        load = nil
        initializer = self
        $__cucumber_toplevel.Before do
          load = initializer.dataset_session.load_datasets_for(initializer.class)
          extend_from_dataset_load(load)
        end
        # Makes sure the datasets are reloaded after each scenario
        ::Cucumber::Rails::World.use_transactional_fixtures = true
      end
      
      alias_method :use, :load
      
      def datasets_directory(directory)
        context_methods = Class.new do
          include Dataset::ContextClassMethods
        end
        context_methods.new.datasets_directory(directory)
      end
    end
    
    module Cucumber # :nodoc:      
      def Datasets(&block)
        raise "A block is required when calling Datasets" unless block_given?
        
        initializer = CucumberInitializer.new
        initializer.instance_eval(&block)
      end
      
      def self.load_world(target)
        target.World(Dataset::Extensions::WorldTest)
        target.World(Dataset::InstanceMethods)
      end
    end    
    
    module WorldTest
      def test_method
        puts "test_method was called"
      end
    end
  end
end

Dataset::Extensions::Cucumber.load_world(self)
extend(Dataset::Extensions::Cucumber)
