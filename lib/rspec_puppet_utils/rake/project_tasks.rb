require 'rake'
require 'rspec/core/rake_task'
require 'fileutils'

# ToDo: Add flag to include version in package file name or not e.g. puppet-1.2.3.zip
# ToDo: replace zip cmds with ruby zip lib to avoid shelling out

module Rake

  class Puppet

    attr_accessor :module_path, :excluded_modules
    attr_accessor :package_dir, :package_files, :package_version

    @module_path      # The directory containing all the modules to test
    @excluded_dirs    # Directories excluded from rspec search
    @excluded_modules # Modules to exclude from rspec testing
    @package_dir      # Where the puppet zip package will be created
    @package_files    # Files and directories to include in the package
    @package_name     # Name of the package
    @package_version  # The version of the package (e.g. 2.1.0)

    def initialize
      extend Rake::DSL  # makes 'namespace' and 'task' methods available to instance

      @module_path      = 'modules' # Deliberately excludes modules-lib dir
      @excluded_dirs    = ['.', '..']
      @excluded_modules = []
      @package_dir      = 'pkg'
      @package_files    = ['modules', 'modules-lib', 'config/environment.conf']
      @package_name     = 'puppet'
      @package_version  = nil
    end

    def load_tasks
      load_spec_tasks
      load_build_tasks
    end

    def testable_modules
      raise ArgumentError, 'Excluded modules must be an array' unless @excluded_modules.is_a? Array
      module_dirs = Dir.entries(@module_path) - @excluded_dirs - @excluded_modules
      module_dirs.select! {|e| File.directory?("#{@module_path}/#{e}/spec") }
      module_dirs
    end

    def load_spec_tasks

      modules      = testable_modules
      module_tasks = modules.collect { |m| "#{:spec}:#{m}" }

      namespace :spec do
        modules.each { |puppet_module|
          module_root = "#{@module_path}/#{puppet_module}"
          opts_path   = "#{module_root}/spec/spec.opts"

          desc "Run #{puppet_module} module specs"
          RSpec::Core::RakeTask.new puppet_module do |t|
            t.ruby_opts  = "-C#{module_root}"
            t.rspec_opts = File.exists?(opts_path) ? File.read(opts_path).chomp : ''
          end
        }
      end

      desc 'Run specs in all modules'
      task :spec    => module_tasks
      task :default => :spec
    end

    def load_build_tasks

      raise(ArgumentError, 'Please provide a package_version (e.g. "1.0.0")') if @package_version.nil?

      namespace :build do

        # The build_dir (i.e. 'puppet') is the root dir of the files when the zip is extracted
        build_dir = "#{@package_dir}/puppet"

        # Preps build directory
        task :prep do
          puts 'Preparing build'
          FileUtils.rm_r @package_dir if File.exist?(@package_dir)
          FileUtils.mkdir_p build_dir
          @package_files.each {|f|
            if File.exist? f
              puts "Copying #{f} to #{build_dir}"
              FileUtils.cp_r f, build_dir
            else
              fail "Could not find #{f} file or directory: Ensure that the package_files list is correct"
            end
          }
        end

        task :package => [:prep] do
          # Exclude modules' spec directories as they're not needed once deployed
          exclude_patterns = '-x puppet/modules/\*/spec/\* puppet/modules-lib/\*/spec/\*'
          cmds = ["cd #{@package_dir}", '&&', "zip -qr #{@package_name}.zip . #{exclude_patterns}", '&&', 'cd -']
          puts `#{cmds.join(' ')}`
        end

        task :cleanup do
          puts "Cleaning up #{build_dir}/"
          FileUtils.rm_r build_dir if File.exist?(build_dir)
        end
      end

      desc "Build #{@package_name}.zip v#{@package_version} without tests"
      task :quick_build => ['build:package', 'build:cleanup'] do
        puts "Built #{@package_name}.zip version #{@package_version}"
      end

      desc "Build #{@package_name}.zip v#{@package_version}"
      task :build => [:spec, :quick_build]
    end

  end
end
