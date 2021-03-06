module RSpecPuppetUtils
  module HieraData

    class Validator

      attr_reader :data, :load_errors

      def validate(key, required_files = [], &block)
        pre_checks(required_files)
        @found = false
        @data.keys.each do |file|
          validate_file file, key, required_files, &block
        end
        raise ValidationError, "No match for #{key.inspect} was not found in any files" unless @found
        raise ValidationError, "No match for #{key.inspect} was not found in: #{required_files.join ', '}" unless required_files.empty?
      end

      private

      def pre_checks(required_files)
        raise ValidationError, "Errors occurred during data load:\n#{@load_errors.join "\n"}\n" unless @load_errors.empty?
        raise StandardError, 'No data available, try #load first' if @data.nil? || @data.empty?
        raise ArgumentError, 'required files should be an Array' unless required_files.is_a?(Array)
      end

      def validate_file(file, key, required_files, &block)
        keys = get_matching_keys key, file
        keys.each do |matched_key|
          @found = true
          begin
            required_files.delete file
            block.call @data[file][matched_key]
          rescue RSpec::Expectations::ExpectationNotMetError => e
            raise ValidationError, "#{matched_key} is invalid in #{file}: #{e.message}"
          end
        end
      end

      def get_matching_keys(key, file)
        if key.is_a?(String) || key.is_a?(Symbol)
          keys = @data[file].has_key?(key) ? [key] : []
        elsif key.is_a?(Regexp)
          keys = @data[file].keys.select { |k| k.to_s =~ key }
        else
          raise ArgumentError, 'Search key must be a String, Symbol or a Regexp'
        end
        keys
      end

    end

    class ValidationError < StandardError
    end

  end
end
