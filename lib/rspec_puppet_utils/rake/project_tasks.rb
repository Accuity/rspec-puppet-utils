require 'rake'
require 'rspec/core/rake_task'
require 'fileutils'

# ToDo: replace zip cmds with ruby zip lib to avoid shelling out
# ToDo: What if no lib dir exists?

module Rake

  class Puppet

    attr_accessor :excluded_modules, :package_dir, :package_files, :package_version, :package_versioning

    # @librarian_dir      (string)   Directory where librarian-puppet installs modules (default "modules")
    # @site_dir           (string)   Directory for profiles, roles and components (default "site")
    # @lib_dir            (string)   Directory for custom/internal modules (default "lib")
    # @excluded_dirs      (string[]) Directories excluded from spec search
    # @excluded_modules   (string[]) Modules excluded from spec testing
    # @package_dir        (string)   Where the puppet zip package will be created
    # @package_files      (string[]) Files and directories to include in the package
    # @package_name       (string)   Name of the package
    # @package_version    (string)   The version of the package (e.g. 2.1.0)
    # @package_versioning (boolean)  Is the version included in the package name?

    def initialize
      extend Rake::DSL  # makes 'namespace' and 'task' methods available to instance

      @librarian_dir      = 'modules'
      @site_dir           = 'site'
      @lib_dir            = 'lib'
      @excluded_dirs      = ['.', '..']
      @excluded_modules   = []
      @package_dir        = 'pkg'
      @package_files      = ['hieradata', 'environment.conf']
      @package_name       = 'puppet'
      @package_version    = nil
      @package_versioning = true
    end

    def load_tasks
      validate_unique_module_names
      load_module_tasks
      load_build_tasks
    end

    # private

    def testable_modules
      raise ArgumentError, 'excluded_modules must be an array' unless @excluded_modules.is_a? Array
      modules = []
      [@lib_dir, @site_dir].each { |module_dir|
        raise ArgumentError, "Module path #{module_dir} could not be found" unless Dir.exist?(module_dir)
        entries = Dir.entries(module_dir) - @excluded_dirs - @excluded_modules
        modules.concat entries.collect { |entry| "#{module_dir}/#{entry}" }
      }
      filter_modules modules
    end

    def filter_modules(modules)
      modules.select! { |m| module_has_specs?(m) and module_has_rakefile?(m) }
      modules
    end

    def module_has_specs?(module_dir)
      File.directory? "#{module_dir}/spec"
    end

    def module_has_rakefile?(module_dir)
      rakefiles = ['rakefile', 'rakefile.rb']
      entries   = Dir.entries module_dir
      entries.collect! { |f| f.downcase }
      rakefiles.each { |rf| return true if entries.include? rf }
      false
    end

    def validate_unique_module_names
      # & == intersection : Returns elements common to the both arrays
      duplicates =  Dir.entries(@site_dir) & Dir.entries(@librarian_dir)
      duplicates += Dir.entries(@librarian_dir) & Dir.entries(@lib_dir)
      duplicates += Dir.entries(@lib_dir) & Dir.entries(@site_dir)
      duplicates -= @excluded_dirs
      fail "Duplicate module names: #{duplicates.join ', '}" unless duplicates.empty?
    end

    def load_module_tasks

      modules      = testable_modules
      module_names = testable_modules.collect { |m| m.split('/')[1] }
      spec_tasks   = module_names.collect { |mn| "#{mn}:#{:spec}" }

      modules.each_with_index { |module_path, i|

        module_name = module_names[i]

        namespace module_name do
          desc "Run #{module_name} module specs"
          task :spec do
            Dir.chdir module_path do
              success = system('rake spec') # This isn't perfect but ...
              exit 1 unless success
            end
          end
        end
      }

      desc 'Run specs in all modules'
      task :spec    => spec_tasks
      task :default => :spec
    end

    def load_build_tasks

      raise ArgumentError, 'Please provide a package_version (e.g. "1.0.0")' if @package_version.nil?

      full_package_name = @package_versioning ? "puppet-#{@package_version}.zip" : 'puppet.zip'
      package_desc      = @package_versioning ? full_package_name : "#{full_package_name} v#{@package_version}"
      package_path      = File.expand_path "#{@package_dir}/#{full_package_name}"
      build_dir         = "#{@package_dir}/puppet"

      namespace :build do

        # Preps build directory
        task :prep do
          puts 'Preparing build'

          FileUtils.rm package_path if File.exist?(package_path)
          FileUtils.rm_r build_dir if File.exist?(build_dir)
          FileUtils.mkdir_p build_dir
        end

        task :copy_files => [:prep] do

          # Copy librarian and site modules into build dir
          puts 'Copying external and site modules'
          FileUtils.cp_r @site_dir, build_dir
          FileUtils.cp_r @librarian_dir, build_dir

          # Copy lib modules into the librarian build dir
          puts 'Copying lib modules'
          FileUtils.cp_r "#{@lib_dir}/.", "#{build_dir}/#{@librarian_dir}"

          # Copy other package files
          @package_files.each {|f|
            fail "Could not find package file or directory #{f}" unless File.exist? f
            puts "Copying #{f} to #{build_dir}"
            FileUtils.cp_r f, build_dir
          }
        end

        task :package => [:copy_files] do
          puts "Creating #{full_package_name}"
          # Exclude all the spec code as it's not needed once deployed
          exclude_patterns = ['\*/\*/spec/\*']
          exclude_string   = "-x #{exclude_patterns.join(' ')}"
          FileUtils.cd(build_dir) {
            out = `zip -qr #{package_path} . #{exclude_string}`
            fail("Error creating package: #{out}") unless $?.exitstatus == 0
          }
        end

        task :cleanup do
          puts "Cleaning up #{build_dir}"
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
