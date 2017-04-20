require 'spec_helper'
require 'lib/rspec_puppet_utils/rake/project_tasks'

describe Rake::Puppet do

  testable_module_names = [ 'core', 'base' ]
  testable_modules = [ 'lib/core', 'lib/base' ]
  sample_modules   = [ 'lib/core', 'lib/base', 'site/role', 'site/profile' ]
  rakefile_names   = [ 'Rakefile', 'rakefile', 'Rakefile.rb', 'rakefile.rb' ]

  let(:puppet) { Rake::Puppet.new }

  it 'allows adding to package_files list' do
    initial_count = puppet.package_files.count
    puppet.package_files << 'extra_file'
    expect(puppet.package_files).to include 'extra_file'
    expect(puppet.package_files.count).to eq initial_count + 1
  end

  describe 'load_module_tasks' do

    before(:each) do
      puppet.stubs(:testable_modules).returns(testable_modules) # not exactly best practice, but hey
    end

    it 'includes namespace and task methods from Rake::DSL' do
      # It would throw error on load if task or namespace methods are missing
      expect { puppet.load_module_tasks }.to_not raise_error
    end

    it 'creates a task for each module' do
      puppet.load_module_tasks
      testable_module_names.each { |mod|
        expect(Rake::Task.task_defined?("#{mod}:spec")).to eq true
      }
    end

    it 'loads the main spec task' do
      puppet.load_module_tasks
      expect(Rake::Task.task_defined?(:spec)).to eq true
    end

    it 'makes module spec tasks prerequisites of main spec task' do
      puppet.load_module_tasks
      task_names = testable_module_names.collect { |mn| "#{mn}:spec" }
      prerequisites = Rake::Task[:spec].prerequisites
      expect(prerequisites).to match_array task_names
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
      }

      it 'loads the "build" task' do
        puppet.load_build_tasks
        expect(Rake::Task.task_defined?(:build)).to eq true
      end

      it 'loads the "quick_build" task' do
        puppet.load_build_tasks
        expect(Rake::Task.task_defined?(:quick_build)).to eq true
      end

      it 'includes package_version in package name' do
        puppet.load_build_tasks
        build_task = Rake::Task[:build]
        expect(build_task.application.last_description).to match /puppet-#{package_version}.zip/
      end

      context 'when package_versioning is turned off' do

        before(:each) do
          puppet.package_versioning = false
        end

        it 'omits the version from the package name' do
          puppet.load_build_tasks
          build_task = Rake::Task[:build]
          expect(build_task.application.last_description).to match /puppet.zip/
        end

        it 'includes the version in the task description' do
          puppet.load_build_tasks
          build_task = Rake::Task[:build]
          expect(build_task.application.last_description).to match /v#{package_version}/
        end

      end

    end

  end

  describe 'filter_modules' do

    before(:each) do
      Dir.stubs(:entries).returns []
    end

    it 'filters modules with a spec directory' do
      Dir.stubs(:entries).returns rakefile_names # bypass Rakefile filter

      File.stubs(:directory?).returns false
      File.stubs(:directory?).with(regexp_matches( /^(#{testable_modules.join '|'})\/spec$/ )).returns(true)

      result = puppet.filter_modules sample_modules
      expect(result).to match_array testable_modules
    end

    rakefile_names.each { |filename|
      it 'filters modules with a Rakefile' do
        File.stubs(:directory?).returns true # bypass spec dir filter

        Dir.stubs(:entries).with(regexp_matches( /^#{testable_modules.join '|'}/ )).returns([filename])

        result = puppet.filter_modules sample_modules
        expect(result).to match_array testable_modules
      end
    }

  end

  describe 'testable_modules' do

    before(:each) do
      # Bypass the filter logic. Again, not exactly best practice, but hey
      def puppet.filter_modules(_modules)
        _modules
      end

      Dir.stubs(:exist?).returns true
      Dir.stubs(:entries).with('lib').returns(['one', 'two'])
      Dir.stubs(:entries).with('site').returns(['three', 'four'])
      Dir.stubs(:entries).with('extra').returns(['five', 'six'])
    end

    it 'finds modules in all paths' do
      puppet.module_dirs << 'extra'
      modules = ['lib/one', 'lib/two', 'site/three', 'site/four', 'extra/five', 'extra/six']
      expect(puppet.testable_modules).to match_array modules
    end

    it 'ignores excluded directories' do
      Dir.stubs(:entries).with('lib').returns(['.', '..', 'one', 'two'])
      modules = ['lib/one', 'lib/two', 'site/three', 'site/four']
      expect(puppet.testable_modules).to match_array modules
    end

    it 'ignores excluded modules' do
      puppet.excluded_modules = ['two', 'four']
      modules = ['lib/one', 'site/three']
      expect(puppet.testable_modules).to match_array modules
    end

    it 'raises an error if module_paths is not an array' do
      puppet.module_dirs = 'not an array'
      expect { puppet.testable_modules }.to raise_error(ArgumentError, /must be an array/)
    end

    it 'raises an error if excluded modules is not an array' do
      puppet.excluded_modules = 'not an array'
      expect { puppet.testable_modules }.to raise_error(ArgumentError, /must be an array/)
    end

    it 'raises an error if a path directory does not exist' do
      Dir.stubs(:exist?).with('lib').returns false
      expect {
        puppet.testable_modules
      }.to raise_error(ArgumentError, /lib could not be found/)
    end

  end

end
