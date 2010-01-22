require 'rubygems'
require 'plugit'

PLUGIT_ROOT = File.expand_path(File.dirname(__FILE__))

Plugit.describe do |dataset|
  dataset.environments_root_path = "#{PLUGIT_ROOT}/environments"
  vendor_directory               = "#{PLUGIT_ROOT}/../vendor/plugins"
  
  dataset.environment :default, 'Released versions of Rails and RSpec' do |env|
    env.library :rails, :export => "git clone git://github.com/rails/rails.git" do |rails|
      rails.after_update { `git fetch origin 2-3-stable:2-3-stable; git checkout 2-3-stable` }
      rails.load_paths = %w{/activesupport/lib /activerecord/lib /actionpack/lib /railties/lib}
      rails.requires = %w{active_support active_record active_record/fixtures action_controller action_view initializer}
    end
    env.library :rspec, :export => "git clone git://github.com/dchelimsky/rspec.git" do |rspec|
      rspec.after_update { `git checkout v1.3.0 && mkdir -p #{vendor_directory} && ln -nsf #{File.expand_path('.')} #{vendor_directory + '/rspec'}` }
      rspec.requires = %w{spec}
    end
    env.library :rspec_rails, :export => "git clone git://github.com/dchelimsky/rspec-rails.git" do |rspec_rails|
      rspec_rails.after_update { `git checkout v1.3.2 && mkdir -p #{vendor_directory} && ln -nsf #{File.expand_path('.')} #{vendor_directory + '/rspec_rails'}` }
      rspec_rails.before_install do 
        class ApplicationController
        end
      end
      rspec_rails.requires = %w{spec/rails}
    end
    env.library :cucumber, :export => "git clone git://github.com/aslakhellesoy/cucumber.git" do |cukes|
      cukes.after_update { `git fetch origin master; git checkout v0.6.1` }
      cukes.requires = %w{cucumber cucumber/rb_support/rb_language}
    end
    env.library :cucumber_rails, :export => "git clone git://github.com/aslakhellesoy/cucumber-rails.git" do |cukes_rails|
      cukes_rails.after_update { `git fetch origin master; git checkout v0.2.4`}
      cukes_rails.requires = %w{cucumber/rails/world cucumber/rails/rspec cucumber/rails/active_record}
      cukes_rails.before_install do
        Rails.configuration = Rails::Configuration.new
        Cucumber::RbSupport::RbLanguage.new(Cucumber::StepMother.new)
      end
    end
  end
end