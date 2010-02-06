SPEC_ROOT = File.expand_path(File.dirname(__FILE__))
require "#{SPEC_ROOT}/../plugit/descriptor"
require 'pathname'

# From RSpec's spec_helper.rb. Necessary to run an example group.
def with_sandboxed_options
  attr_reader :options
  
  before(:each) do
    @original_rspec_options = ::Spec::Runner.options
    ::Spec::Runner.use(@options = ::Spec::Runner::Options.new(StringIO.new, StringIO.new))
  end
  
  after(:each) do
    ::Spec::Runner.use(@original_rspec_options)
  end
  
  yield
end

$LOAD_PATH << SPEC_ROOT
RAILS_ROOT = (Pathname.new(SPEC_ROOT) + "..").to_s unless defined?(RAILS_ROOT)
$LOAD_PATH << "#{RAILS_ROOT}/lib"
RAILS_LOG_FILE = "#{RAILS_ROOT}/log/test.log"
SQLITE_DATABASE = "#{SPEC_ROOT}/sqlite3.db"
TEMP_PATH = "#{SPEC_ROOT}/tmp/tmp"

require 'fileutils'
FileUtils.mkdir_p(File.dirname(RAILS_LOG_FILE))
FileUtils.touch(RAILS_LOG_FILE)
FileUtils.mkdir_p("#{SPEC_ROOT}/tmp")
FileUtils.rm_f(Dir.glob("#{SPEC_ROOT}/tmp/*"))
FileUtils.rm_f(Dir.glob("#{RAILS_ROOT}/tmp/dataset/*"))
FileUtils.rm_f(SQLITE_DATABASE)
FileUtils.mkdir_p(TEMP_PATH)
FileUtils.rm_f("#{TEMP_PATH}/*")

require 'logger'
RAILS_DEFAULT_LOGGER = Logger.new(RAILS_LOG_FILE)
RAILS_DEFAULT_LOGGER.level = Logger::DEBUG

ActiveRecord::Base.silence do
  ActiveRecord::Base.configurations = {'test' => {
    'adapter' => 'sqlite3',
    'database' => SQLITE_DATABASE
  }}
  ActiveRecord::Base.establish_connection 'test'
  load "#{SPEC_ROOT}/schema.rb"
end

require "models"
require "dataset"

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
        true
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
