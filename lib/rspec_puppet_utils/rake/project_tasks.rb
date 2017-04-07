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
      @package_files      = ['modules', 'modules-lib', 'config/environment.conf']
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
              exit success ? 0 : 1
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

      # The build_dir (i.e. 'puppet') is the root dir of the files when the zip is extracted
      build_dir         = "#{@package_dir}/puppet"
      full_package_name = @package_versioning ? "puppet-#{@package_version}.zip" : 'puppet.zip'
      package_desc      = @package_versioning ? full_package_name : "#{full_package_name} v#{@package_version}"

      namespace :build do

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
          cmds = ["cd #{@package_dir}", '&&', "zip -qr #{full_package_name} . #{exclude_patterns}", '&&', 'cd -']
          puts `#{cmds.join(' ')}`
        end

        task :cleanup do
          puts "Cleaning up #{build_dir}/"
          FileUtils.rm_r build_dir if File.exist?(build_dir)
        end
      end

      desc "Build #{package_desc} without tests"
      task :quick_build => ['build:package', 'build:cleanup'] do
        puts "Built #{package_desc}"
      end

      desc "Build #{package_desc}"
      task :build => [:spec, :quick_build]
    end

  end
end
