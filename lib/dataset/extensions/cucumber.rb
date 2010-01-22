$__cucumber_toplevel = self

module Dataset
  module Extensions # :nodoc:
    class CucumberInitializer # :nodoc:
      include Dataset
      
      def load(datasets)
        datasets.each do |dataset|
          puts "Adding dataset"
          self.class.add_dataset(dataset)
        end

        load = nil
        initializer = self
        $__cucumber_toplevel.Before do
          load = initializer.dataset_session.load_datasets_for(initializer.class)
          initializer.extend_from_dataset_load(load)
        end
        # Makes sure the datasets are reloaded after each scenario
        ::Cucumber::Rails::World.use_transactional_fixtures = true
      end
    end
    
    module Cucumber # :nodoc:      
      def Datasets
        raise "A block is required when calling Datasets" unless block_given?
        initializer = CucumberInitializer.new
        datasets = yield
        initializer.load(datasets)
      end
    end    
  end
end

extend(Dataset::Extensions::Cucumber)