require 'spec_helper'
require 'lib/rspec_puppet_utils/rake/project_tasks'

describe Rake::Puppet do

  module_path      = 'modules'
  testable_modules = [ 'core', 'base' ]
  modules_dir_list = [ 'core', 'base', 'role', 'profiles' ]

  let(:puppet) { Rake::Puppet.new }

  describe 'load_spec_tasks' do

    before(:each) do
      puppet.stubs(:testable_modules).returns(testable_modules) # not exactly best practice, but hey
    end

    it 'includes namespace and task methods from Rake::DSL' do
      # It would throw error on load if task or namespace methods are missing
      expect { puppet.load_spec_tasks }.to_not raise_error
    end

    it 'creates a task for each module' do
      puppet.load_spec_tasks
      testable_modules.each { |mod|
        expect(Rake::Task.task_defined?("spec:#{mod}")).to eq true
      }
    end

    it 'loads the main spec task' do
      puppet.load_spec_tasks
      expect(Rake::Task.task_defined?(:spec)).to eq true
    end

  end

  describe 'load_build_tasks' do

    it 'fails if no version is provided' do
      expect { puppet.load_build_tasks }.to raise_error(ArgumentError, /provide a package_version/)
    end

    context 'when version is set' do

      let(:package_version) { '1.2.3' }
      before(:each) {
        puppet.package_version = package_version
        puppet.load_build_tasks
      }

      it 'loads the "build" task' do
        expect(Rake::Task.task_defined?(:build)).to eq true
      end

      it 'loads the "quick_build" task' do
        expect(Rake::Task.task_defined?(:quick_build)).to eq true
      end

      it 'includes package_version in task description' do
        build_task = Rake::Task[:build]
        expect(build_task.application.last_description).to match /v#{package_version}/
      end

    end

  end

  describe 'testable_modules' do

    it 'finds modules with a spec directory' do
      Dir.stubs(:entries).with(module_path).returns modules_dir_list.clone

      File.stubs(:directory?).returns(false)
      File.stubs(:directory?).with(regexp_matches( /(#{testable_modules.join '|'})\/spec$/ )).returns(true)

      result = puppet.testable_modules
      expect(result).to match_array testable_modules
    end

    it 'finds modules within module_path' do
      alt_module_path = 'modules-alt'

      Dir.expects(:entries).with(alt_module_path).returns testable_modules
      testable_modules.each { |m|
        File.expects(:directory?).with(regexp_matches( /#{alt_module_path}\/#{m}/ )).returns(true)
      }

      puppet.module_path = alt_module_path
      puppet.testable_modules
    end

    it 'ignores excluded modules' do
      Dir.stubs(:entries).with(module_path).returns testable_modules.clone
      File.stubs(:directory?).returns(true)

      puppet.excluded_modules = ['core']
      result = puppet.testable_modules
      expect(result).to match_array ['base']
    end

    it 'throws error if excluded modules is not an array' do
      puppet.excluded_modules = 'not an array'
      expect { puppet.testable_modules }.to raise_error(ArgumentError, /must be an array/)
    end

    it 'ignores excluded directories' do
      Dir.stubs(:entries).with(module_path).returns testable_modules + ['.', '..']
      File.stubs(:directory?).returns(true)

      result = puppet.testable_modules
      expect(result).to match_array testable_modules
    end

  end

end