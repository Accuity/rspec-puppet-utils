require 'hieradata/validator'
require 'yaml'

module HieraData

  class YamlValidator < Validator

    def initialize(directory, extension = 'yaml')
      @directory = directory
      @extension = extension =~ /\..*/ ? extension : ".#{extension}"
    end

    def load(ignore_empty = false)

      files = Dir.glob(File.join(@directory, '**', '*')).reject { |path|
        File.directory?(path) || File.extname(path) != @extension
      }

      @data = {}
      files.each { |file|

        # Assume all file names are unique i.e. thing.yaml and thing.yml don't both exist
        file_name = File.basename file, @extension

        begin
          yaml = File.open(file) { |yf|
            YAML::load( yf )
          }
        rescue ArgumentError => e
          raise StandardError, "Yaml Syntax error in file #{file}: #{e.message}"
        end
        raise StandardError, "Yaml file is empty: #{file}" if !yaml && !ignore_empty

        @data[file_name.to_sym] = yaml
      }

    end
  end
end
