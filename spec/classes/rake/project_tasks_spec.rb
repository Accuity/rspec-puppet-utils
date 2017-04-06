require 'spec_helper'
require 'lib/rspec_puppet_utils/rake/project_tasks'

describe Rake::Puppet do

  module_path      = 'modules'
  testable_modules = [ 'core', 'base' ]
  modules_dir_list = [ 'core', 'base', 'role', 'profiles' ]
  rakefile_names   = ['Rakefile', 'rakefile', 'Rakefile.rb', 'rakefile.rb']

  let(:puppet) { Rake::Puppet.new }

  it 'allows adding to package_files list' do
    initial_count = puppet.package_files.count
    puppet.package_files << 'extra_file'
    expect(puppet.package_files).to include 'extra_file'
    expect(puppet.package_files.count).to eq initial_count + 1
  end

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
      File.stubs(:directory?).with(regexp_matches( /(#{testable_modules.join '|'})\/spec$/ )).returns(true)

      result = puppet.filter_modules modules_dir_list
      expect(result).to match_array testable_modules
    end

    rakefile_names.each { |filename|
      it 'filters modules with a Rakefile' do
        File.stubs(:directory?).returns true # bypass spec dir filter

        Dir.stubs(:entries).with(regexp_matches( /#{testable_modules.join '|'}/ )).returns([filename])

        result = puppet.filter_modules modules_dir_list
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
    end

    it 'ignores excluded directories' do
      Dir.stubs(:entries).with(module_path).returns testable_modules + ['.', '..']

      result = puppet.testable_modules
      expect(result).to match_array testable_modules
    end

    it 'ignores excluded modules' do
      Dir.stubs(:entries).with(module_path).returns testable_modules + ['exclude_me']

      puppet.excluded_modules = ['exclude_me']
      result = puppet.testable_modules
      expect(result).to match_array testable_modules
    end

    it 'throws error if excluded modules is not an array' do
      puppet.excluded_modules = 'not an array'
      expect { puppet.testable_modules }.to raise_error(ArgumentError, /must be an array/)
    end

    it 'finds modules within module_path' do
      alt_module_path = 'modules-alt'

      Dir.expects(:entries).with(alt_module_path).returns modules_dir_list

      puppet.module_path = alt_module_path
      puppet.testable_modules
    end

  end

end