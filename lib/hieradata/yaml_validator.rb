require 'hieradata/validator'
require 'yaml'

module RSpecPuppetUtils
  module HieraData

    class YamlValidator < HieraData::Validator

      def initialize(directory, extensions = ['yaml', 'yml'])
        raise ArgumentError, 'extensions should be an Array' unless extensions.is_a? Array
        @directory = directory
        @extensions = extensions.map {|ext| ext =~ /\..*/ ? ext : ".#{ext}" }
      end

      def load(ignore_empty = false)
        warn '#load is deprecated, use #load_data instead'
        ignore_empty ? load_data(:ignore_empty) : load_data
      end

      def load_data(*args)
        files = Dir.glob(File.join(@directory, '**', '*')).reject { |path|
          File.directory?(path) || !@extensions.include?(File.extname path )
        }

        @data = {}
        files.each { |file|

          # Assume all file names are unique i.e. thing.yaml and thing.yml don't both exist
          file_name = File.basename(file).split('.').first

          begin
            yaml = File.open(file) { |yf|
              YAML::load( yf )
            }
          rescue ArgumentError => e
            raise ValidationError, "Yaml Syntax error in file #{file}: #{e.message}"
          end
          raise ValidationError, "Yaml file is empty: #{file}" unless yaml || args.include?(:ignore_empty)

          @data[file_name.to_sym] = yaml if yaml
        }
        self
      end

    end

  end
end
