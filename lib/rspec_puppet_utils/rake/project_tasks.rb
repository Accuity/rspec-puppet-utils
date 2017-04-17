require 'rake'
require 'rspec/core/rake_task'
require 'fileutils'

# ToDo: replace zip cmds with ruby zip lib to avoid shelling out

module Rake

  class Puppet

    attr_accessor :module_path, :excluded_modules
    attr_accessor :package_dir, :package_files, :package_version, :package_versioning

    @module_path        # (string)   The directory containing all the modules to test
    @excluded_dirs      # (string[]) Directories excluded from rspec search
    @excluded_modules   # (string[]) Modules excluded from rspec testing
    @package_dir        # (string)   Where the puppet zip package will be created
    @package_files      # (string[]) Files and directories to include in the package
    @package_name       # (string)   Name of the package
    @package_version    # (string)   The version of the package (e.g. 2.1.0)
    @package_versioning # (boolean)  Is the version included in the package name?

    def initialize
      extend Rake::DSL  # makes 'namespace' and 'task' methods available to instance

      @module_path        = 'modules' # Deliberately excludes modules-lib dir
      @excluded_dirs      = ['.', '..']
      @excluded_modules   = []
      @package_dir        = 'pkg'
      @package_files      = ['modules', 'modules-lib', 'environment.conf']
      @package_name       = 'puppet'
      @package_version    = nil
      @package_versioning = true
    end

    def load_tasks
      load_module_tasks
      load_build_tasks
    end

    def testable_modules
      raise ArgumentError, 'Excluded modules must be an array' unless @excluded_modules.is_a? Array
      module_dirs = Dir.entries(@module_path) - @excluded_dirs - @excluded_modules
      filter_modules module_dirs
    end

    def filter_modules(module_dirs)
      module_dirs.select! { |m| module_has_specs?(m) and module_has_rakefile?(m) }
      module_dirs
    end

    def module_has_specs?(module_dir)
      File.directory?("#{@module_path}/#{module_dir}/spec")
    end

    def module_has_rakefile?(module_dir)
      rakefiles = ['rakefile', 'rakefile.rb']
      entries   = Dir.entries("#{@module_path}/#{module_dir}")
      entries.collect! { |f| f.downcase }
      rakefiles.each { |rf| return true if entries.include? rf }
      false
    end

    def load_module_tasks

      modules    = testable_modules
      spec_tasks = modules.collect { |m| "#{m}:#{:spec}" }
      # lint_tasks = modules.collect { |m| "#{m}:#{:lint}" }

      modules.each { |puppet_module|
        namespace puppet_module do

          desc "Run #{puppet_module} module specs"
          task :spec do
            Dir.chdir "#{@module_path}/#{puppet_module}" do
              success = system('rake spec') # This isn't perfect but ...
              exit 1 unless success
            end
          end

        end
      }

      # desc 'Run lint checks for all modules'
      # task :lint => lint_tasks

      desc 'Run specs in all modules'
      task :spec    => spec_tasks
      task :default => :spec

    end

    def load_build_tasks

      raise(ArgumentError, 'Please provide a package_version (e.g. "1.0.0")') if @package_version.nil?

      full_package_name = @package_versioning ? "puppet-#{@package_version}.zip" : 'puppet.zip'
      package_desc      = @package_versioning ? full_package_name : "#{full_package_name} v#{@package_version}"
      package_path      = "#{@package_dir}/#{full_package_name}"

      namespace :build do

        # Preps build directory
        task :prep do
          puts 'Preparing build'
          FileUtils.mkdir_p @package_dir
          FileUtils.rm package_path if File.exist?(package_path)
        end

        task :package => [:prep] do
          # Exclude all the spec code as it's not needed once deployed
          exclude_patterns = ['modules/\*/spec/\*', 'modules-lib/\*/spec/\*']
          exclude_string   = "-x #{exclude_patterns.join(' ')}"
          include_string   = @package_files.join(' ')
          cmd     = "zip -qr #{package_path} #{include_string} #{exclude_string}"
          success = system(cmd)
          exit 1 unless success
        end

      end

      desc "Build #{package_desc} without tests"
      task :quick_build => 'build:package' do
        puts "Built #{package_desc}"
      end

      desc "Build #{package_desc}"
      task :build => [:spec, :quick_build]
    end

  end
end
