require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

$:.unshift(File.dirname(__FILE__) + '/../stubs')
require "mini_rails"

require 'cucumber/rb_support/rb_language'
require 'cucumber/ast'
require 'cucumber/rails/world'
require 'cucumber/rails/rspec'
require 'dataset/extensions/cucumber'
require 'cucumber/formatter/pretty'

$__cucumber_root = self

describe Cucumber::Rails::World do
  it 'should have a Datasets method' do
    $__cucumber_root.should respond_to(:Datasets)
  end
  
  it 'should load the dataset when the scenario is run' do
    step_mother = create_step_mother
    
    dataset_load_count = 0
    my_dataset = Class.new(Dataset::Base) do
      define_method(:load) do
        dataset_load_count += 1
      end
    end
    
    $__cucumber_root.Datasets do
      [my_dataset]
    end
    
    given_execute_count = 0
    $__cucumber_root.Given /true is true/ do
      given_execute_count += 1
    end
            
    visitor = Cucumber::Ast::TreeWalker.new(step_mother)
    visitor.options = {}
    
    step_mother.visitor = visitor
    
    scenario = create_scenario_with_step("true is true")
    
    # since everything before this point has just been setup
    # let's make sure that the act of visiting the scenario is
    # what is changing the values
    given_execute_count.should be(0)
    dataset_load_count.should be(0)
    
    visitor.visit_feature_element(scenario)
    
    given_execute_count.should be(1)
    dataset_load_count.should be(1)
  end
  
  def create_step_mother
    step_mother = Cucumber::StepMother.new
    step_mother.load_natural_language('en')
    step_mother.load_programming_language('rb')
    step_mother
  end

  
  def create_scenario_with_step(step_text)
    scenario = Cucumber::Ast::Scenario.new(
      nil,
      Cucumber::Ast::Comment.new(""),
      Cucumber::Ast::Tags.new(8, []),
      9,
      "Scenario:", "A Scenario",
      [
        Cucumber::Ast::Step.new(10, "Given", "true is true")
      ]
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