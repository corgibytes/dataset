require File.expand_path(File.dirname(__FILE__) + "/../spec_helper")

$:.unshift(File.dirname(__FILE__) + "/../stubs")
require "mini_rails"

require "cucumber/rb_support/rb_language"
require "cucumber/ast"
require "cucumber/rails/world"
require "cucumber/rails/rspec"
require "cucumber/formatter/pretty"

require "dataset/extensions/cucumber"

DatasetOne = Class.new(Dataset::Base)
DatasetTwo = Class.new(Dataset::Base)

$__cucumber_root = self

describe "Cucumber Support" do
  before do
    @step_mother, @rb_language = create_step_mother_and_language
    
    @visitor = Cucumber::Ast::TreeWalker.new(@step_mother)
    @visitor.options = {}
    @step_mother.visitor = @visitor    
        
    @cucumber_world = $__cucumber_root
    Dataset::Extensions::Cucumber.load_world(@cucumber_world)
        
  end
  
  describe "cucumber root object" do
    it "should have a Datasets method" do
      @cucumber_world.should respond_to(:Datasets)
    end
  end
  
  describe "Datasets method" do
    it "should allow calling load with a single class" do
      dataset_one_load_count = 0
      dataset_one = Class.new(Dataset::Base) do
        define_method(:load) do
          dataset_one_load_count += 1
        end
      end
      
      @cucumber_world.Datasets do
        load dataset_one
      end
      
      dataset_one_load_count.should be(0)
      run_cucumber
      dataset_one_load_count.should be(1)
    end
    
    it "should allow callling load an array of classes" do
      dataset_one_load_count = 0
      dataset_one = Class.new(Dataset::Base) do
        define_method(:load) do
          dataset_one_load_count += 1
        end
      end
      
      dataset_two_load_count = 0      
      dataset_two = Class.new(Dataset::Base) do
        define_method(:load) do
          dataset_two_load_count += 1
        end
      end
      
      @cucumber_world.Datasets do
        load dataset_one, dataset_two
      end
      
      dataset_one_load_count.should be(0)
      dataset_two_load_count.should be(0)
      run_cucumber
      dataset_one_load_count.should be(1)
      dataset_two_load_count.should be(1)
    end
    
    it "should allow calling load with a single symbol" do
      dataset_one_load_count = 0
      DatasetOne.class_eval do
        define_method(:load) do
          dataset_one_load_count += 1
        end
      end
      
      @cucumber_world.Datasets do
        load :dataset_one
      end
      
      dataset_one_load_count.should be(0)
      run_cucumber
      dataset_one_load_count.should be(1)
    end
    
    it "should allow calling load with an array of symbols" do
      dataset_one_load_count = 0
      DatasetOne.class_eval do
        define_method(:load) do
          dataset_one_load_count += 1
        end
      end
      
      dataset_two_load_count = 0      
      DatasetTwo.class_eval do
        define_method(:load) do
          dataset_two_load_count += 1
        end
      end
      
      @cucumber_world.Datasets do
        load :dataset_one, :dataset_two
      end
      
      dataset_one_load_count.should be(0)
      dataset_two_load_count.should be(0)
      run_cucumber
      dataset_one_load_count.should be(1)
      dataset_two_load_count.should be(1)
    end
    
    it "should allow calling load with a mix of symbols and classes" do
      dataset_one_load_count = 0
      dataset_one = Class.new(Dataset::Base) do
        define_method(:load) do
          dataset_one_load_count += 1
        end
      end
      
      dataset_two_load_count = 0      
      DatasetTwo.class_eval do
        define_method(:load) do
          dataset_two_load_count += 1
        end
      end
            
      @cucumber_world.Datasets do
        load dataset_one, :dataset_two
      end
      
      dataset_one_load_count.should be(0)
      dataset_two_load_count.should be(0)
      run_cucumber
      dataset_one_load_count.should be(1)
      dataset_two_load_count.should be(1)
    end    
    
    it "should allow calling load on seperate lines" do
      dataset_one_load_count = 0
      dataset_one = Class.new(Dataset::Base) do
        define_method(:load) do
          dataset_one_load_count += 1
        end
      end
      
      dataset_two_load_count = 0      
      DatasetTwo.class_eval do
        define_method(:load) do
          dataset_two_load_count += 1
        end
      end
            
      @cucumber_world.Datasets do
        load dataset_one
        load :dataset_two
      end
      
      dataset_one_load_count.should be(0)
      dataset_two_load_count.should be(0)
      run_cucumber
      dataset_one_load_count.should be(1)
      dataset_two_load_count.should be(1)
    end    
    
    it "should allow calling use as an alias of load" do
      dataset_one_load_count = 0
      dataset_one = Class.new(Dataset::Base) do
        define_method(:load) do
          dataset_one_load_count += 1
        end
      end
      
      dataset_two_load_count = 0      
      DatasetTwo.class_eval do
        define_method(:load) do
          dataset_two_load_count += 1
        end
      end
            
      @cucumber_world.Datasets do
        use dataset_one
        use :dataset_two
      end
      
      dataset_one_load_count.should be(0)
      dataset_two_load_count.should be(0)
      run_cucumber
      dataset_one_load_count.should be(1)
      dataset_two_load_count.should be(1)
    end    
    
    it "should allow calling Datasets method more than once" do
      dataset_one_load_count = 0
      dataset_one = Class.new(Dataset::Base) do
        define_method(:load) do
          dataset_one_load_count += 1
        end
      end
      
      dataset_two_load_count = 0      
      DatasetTwo.class_eval do
        define_method(:load) do
          dataset_two_load_count += 1
        end
      end
      
      @cucumber_world.Datasets do
        use dataset_one
      end
      
      @cucumber_world.Datasets do
        use :dataset_two
      end
            
      dataset_one_load_count.should be(0)
      dataset_two_load_count.should be(0)
      run_cucumber
      dataset_one_load_count.should be(1)
      dataset_two_load_count.should be(1)
    end    
    
    
  end
  
  it "should load the dataset when the scenario is run" do
    dataset_load_count = 0
    my_dataset = Class.new(Dataset::Base) do      
      define_method(:load) do
        dataset_load_count += 1
      end
    end
    
    @cucumber_world.Datasets do
      load my_dataset
    end
    
    dataset_load_count.should be(0)
    run_cucumber
    dataset_load_count.should be(1)
  end
  
  it "should let you specify the datasets directory" do
    @cucumber_world.Datasets do
      datasets_directory TEMP_PATH
    end
    
    Dataset::Resolver.default.paths.include?(TEMP_PATH).should be(true)
  end
  
  it "should let you call model finders from a Given method" do
    created_model, found_model = nil
    dataset = Class.new(Dataset::Base) do
      define_method(:load) do
        created_model = create_model(Thing, :mything)
      end
    end
    
    @cucumber_world.Datasets do
      load dataset
    end
    
    @cucumber_world.Given /I am using a model finder/ do
      found_model = things(:mything)
    end
        
    run_cucumber("I am using a model finder")
    found_model.should_not be_nil
    found_model.should == created_model
  end
  
  def run_cucumber(*steps)
    given_execute_count = 0
    @cucumber_world.Given /true is true/ do
      given_execute_count += 1
    end
    
    steps << "true is true"
    @scenario = create_scenario_with_steps(steps)
        
    # since everything before this point has just been setup
    # let"s make sure that the act of visiting the scenario is
    # what is changing the values
    given_execute_count.should be(0)
    
    # run the scenario
    @visitor.visit_feature_element(@scenario)
    
    unless given_execute_count > 0
      puts @scenario.status
      puts @scenario.exception
    end
    
    # now verify that it ran
    given_execute_count.should be(1)
  end
  
  def create_step_mother_and_language
    step_mother = Cucumber::StepMother.new
    step_mother.load_natural_language("en")
    rb_language = step_mother.load_programming_language("rb")
    Cucumber::RbSupport::RbDsl.rb_language = rb_language
    return step_mother, rb_language 
  end

  def create_scenario_with_steps(steps)
    step_index = 10
    scenario_steps = []
    steps.each do |step|
      scenario_steps <<
        Cucumber::Ast::Step.new(step_index, "Given", step)
      step_index += 1
    end
    
    scenario = Cucumber::Ast::Scenario.new(
      nil,
      Cucumber::Ast::Comment.new(""),
      Cucumber::Ast::Tags.new(8, []),
      9,
      "Scenario:", "A Scenario",
      scenario_steps
    )
    
    feature = Cucumber::Ast::Feature.new(
      nil,
      Cucumber::Ast::Comment.new(""),
      Cucumber::Ast::Tags.new(6, []),
      "",
      [scenario])
      
    scenario
  end
end