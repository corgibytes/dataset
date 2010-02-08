$__cucumber_toplevel = self

module Dataset
  module Extensions # :nodoc:
    class CucumberInitializer # :nodoc:
      include Dataset
      
      def initialize
        @datasets = []
        @cucumber_has_been_setup = false
      end
      
      def datasets
        @datasets
      end
            
      def load(*datasets)
        @datasets += datasets

        unless @cucumber_has_been_setup
          load = nil
          initializer = self
          $__cucumber_toplevel.Before do
            # reset the dataset session before each scenario
            unless initializer.dataset_session.nil?
              initializer.dataset_session.reset! 
            end
          
            initializer.datasets.each do |dataset|          
              initializer.class.add_dataset(dataset)
            end
          
            load = initializer.dataset_session.load_datasets_for(initializer.class)
            extend_from_dataset_load(load)
          end
          # Makes sure the datasets are reloaded after each scenario
          ::Cucumber::Rails::World.use_transactional_fixtures = true
          
          @cucumber_has_been_setup = true
        end
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
        
        @initializer = CucumberInitializer.new unless defined? @initalizer
        @initializer.instance_eval(&block)
      end
      
      def self.load_world(target)
        target.World(Dataset::InstanceMethods)
      end
    end    
  end
end

Dataset::Extensions::Cucumber.load_world(self)
extend(Dataset::Extensions::Cucumber)
