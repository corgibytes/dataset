require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

require 'test/unit/testresult'

module Dataset
  module Testing    
    class TestCase < Test::Unit::TestCase
      include Dataset
      
      # rspec monkey patches the suite method and the initialize method. Doing so allows 
      # it to take over execution of the tests. We don't want that here. We want to run
      # directly against Test::Unit. So I have copied this method directly from
      # the 1.8 version of Test::Unit. Is there a way to restore the original method
      # in a programmatic fashion? Or should I patch rspec so that I can get access
      # to the original methods?
  
      def initialize(test_method_name)
        @method_name = test_method_name
        @test_passed = true
      end
      
      def self.suite
        method_names = public_instance_methods(true)
        tests = method_names.delete_if {|method_name| method_name !~ /^test./}
        suite = Test::Unit::TestSuite.new(name)
        tests.sort.each do
          |test|
          catch(:invalid_test) do
            suite << new(test)
          end
        end
        if (suite.empty?)
          catch(:invalid_test) do
            suite << new("default_test")
          end
        end
        return suite
      end
      
      # wiping out the execute method prevents rspec from trying the run the test case
      def execute(run_options, instance_variables)
      end
      
      def run(result)
        yield(STARTED, name)
        @_result = result
        begin
          setup
          __send__(@method_name)
        rescue Test::Unit::AssertionFailedError => e
          puts e
          puts e.backtrace
          add_failure(e.message, e.backtrace)
        rescue Exception
          raise if PASSTHROUGH_EXCEPTIONS.include? $!.class
          puts $!
          puts $!.backtrace
          add_error($!)
        ensure
          begin
            teardown
          rescue Test::Unit::AssertionFailedError => e
            puts e
            puts e.backtrace
            add_failure(e.message, e.backtrace)
          rescue Exception
            raise if PASSTHROUGH_EXCEPTIONS.include? $!.class
            puts $!
            puts $!.backtrace
            add_error($!)
          end
        end
        result.add_run
        yield(FINISHED, name)
      end      
    end   
  end
end
Dataset::Testing::TestCase.extend Dataset::Extensions::TestUnitTestCase

describe Test::Unit::TestCase do
  it 'should have a dataset method' do
    testcase = Class.new(Dataset::Testing::TestCase)
    testcase.should respond_to(:dataset)
  end
  
  it 'should accept multiple datasets' do
    load_count = 0
    dataset_one = Class.new(Dataset::Base) do
      define_method(:load) { load_count += 1 }
    end
    dataset_two = Class.new(Dataset::Base) do
      define_method(:load) { load_count += 1 }
    end
    testcase = Class.new(Test::Unit::TestCase) do
      dataset dataset_one, dataset_two
    end
    run_testcase(testcase)
    load_count.should be(2)
  end
  
  it 'should provide one dataset session for tests' do
    sessions = []
    testcase = Class.new(Dataset::Testing::TestCase) do
      dataset Class.new(Dataset::Base)
      
      define_method(:test_one) do
        sessions << dataset_session
      end
      define_method(:test_two) do
        sessions << dataset_session
      end
    end
    run_testcase(testcase)
    sessions.size.should be(2)
    sessions.uniq.size.should be(1)
  end
  
  it 'should load datasets within class hiearchy' do
    dataset_one = Class.new(Dataset::Base) do
      define_method(:load) do
        Thing.create!
      end
    end
    dataset_two = Class.new(Dataset::Base) do
      define_method(:load) do
        Place.create!
      end
    end
    
    testcase = Class.new(Dataset::Testing::TestCase) do
      dataset(dataset_one)
      def test_one; end
    end
    testcase_child = Class.new(testcase) do
      dataset(dataset_two)
      def test_two; end
    end
    
    run_testcase(testcase)
    Thing.count.should be(1)
    Place.count.should be(0)
    
    run_testcase(testcase_child)
    Thing.count.should be(1)
    Place.count.should be(1)
  end
  
  it 'should forward blocks passed in to the dataset method' do
    load_count = 0
    testcase = Class.new(Dataset::Testing::TestCase) do
      dataset_class = Class.new(Dataset::Base)
      dataset dataset_class do
        load_count += 1
      end
    end
    
    run_testcase(testcase)
    load_count.should == 1
  end
  
  it 'should forward blocks passed in to the dataset method that do not use a dataset class' do
    load_count = 0
    testcase = Class.new(Dataset::Testing::TestCase) do
      dataset do
        load_count += 1
      end
    end
    
    run_testcase(testcase)
    load_count.should == 1
  end
  
  it 'should copy instance variables from block to tests' do
    value_in_test = nil
    testcase = Class.new(Dataset::Testing::TestCase) do
      dataset do
        @myvar = 'Hello'
      end
      define_method :test_something do
        value_in_test = @myvar
      end
    end
    
    run_testcase(testcase)
    value_in_test.should == 'Hello'
  end
  
  it 'should copy instance variables from block to subclass blocks' do
    value_in_subclass_block = nil
    testcase = Class.new(Dataset::Testing::TestCase) do
      dataset do
        @myvar = 'Hello'
      end
    end
    subclass = Class.new(testcase) do
      dataset do
        value_in_subclass_block = @myvar
      end
    end
    
    run_testcase(subclass)
    value_in_subclass_block.should == 'Hello'
  end
  
  it 'should load the dataset when the suite is run' do
    load_count = 0
    dataset = Class.new(Dataset::Base) do
      define_method(:load) do
        load_count += 1
      end
    end
    
    testcase = Class.new(Dataset::Testing::TestCase) do
      dataset(dataset)
      def test_one; end
      def test_two; end
    end
    
    run_testcase(testcase)
    load_count.should be(1)
  end
  
  it 'should expose data reading methods from dataset binding to the test methods through the test instances' do
    created_model, found_model = nil
    dataset = Class.new(Dataset::Base) do
      define_method(:load) do
        created_model = create_model(Thing, :mything)
      end
    end
    
    testcase = Class.new(Dataset::Testing::TestCase) do
      dataset(dataset)
      define_method :test_model_finders do
        found_model = things(:mything)
      end
    end
    
    run_testcase(testcase)
    testcase.should_not respond_to(:things)
    found_model.should_not be_nil
    found_model.should == created_model
  end
  
  it 'should expose dataset helper methods to the test methods through the test instances' do
    dataset_one = Class.new(Dataset::Base) do
      helpers do
        def helper_one; end
      end
      def load; end
    end
    dataset_two = Class.new(Dataset::Base) do
      uses dataset_one
      helpers do
        def helper_two; end
      end
      def load; end
    end
    
    test_instance = nil
    testcase = Class.new(Dataset::Testing::TestCase) do
      dataset(dataset_two)
      define_method :test_model_finders do
        test_instance = self
      end
    end
    
    run_testcase(testcase)
    
    testcase.should_not respond_to(:helper_one)
    testcase.should_not respond_to(:helper_two)
    test_instance.should respond_to(:helper_one)
    test_instance.should respond_to(:helper_two)
  end
  
  def run_testcase(testcase)
    result = Test::Unit::TestResult.new
    testcase.module_eval { def test_dont_complain; end }
    suite = testcase.suite.run(result) {}
    result.failure_count.should be(0)
    result.error_count.should be(0)
    result.run_count.should > 0
  end
end