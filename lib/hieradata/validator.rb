
module RSpecPuppetUtils
  module HieraData

    class Validator

      attr_accessor :data

      def validate?(key, &block)

        raise StandardError, '@data is nil, try load() first' unless @data
        raise StandardError, '@data is empty' if @data.empty?

        found = false
        @data.keys.each do |file|
          if @data[file].has_key? key
            found = true
            valid = block.call(@data[file][key])
            raise StandardError, "Key #{key} is not valid in file #{file}" unless valid
          end
        end
        raise StandardError, "Key #{key} was not found in any files" unless found
      end

    end

  end
end
