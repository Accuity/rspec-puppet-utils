module RSpecPuppetUtils
  module HieraData

    class Validator

      attr_reader :data

      def validate(key, &block)
        raise ValidationError, 'No data available, try #load first' if @data.nil? || @data.empty?

        found = false
        @data.keys.each do |file|
          keys = get_matching_keys(key, file)
          keys.each do |matched_key|
            found = true
            begin
              block.call(@data[file][matched_key])
            rescue Exception => e
              raise ValidationError, "#{matched_key} is invalid in #{file}: #{e.message}"
            end
          end
        end
        raise ValidationError, "No match for #{key.inspect} was not found in any files" unless found
      end

      private

      def get_matching_keys(key, file)
        if key.is_a?(String) || key.is_a?(Symbol)
          keys = @data[file].has_key?(key) ? [key] : []
        elsif key.is_a?(Regexp)
          keys = @data[file].keys.select { |k| k.to_s =~ key }
        else
          raise ValidationError, 'Search key must be a String, Symbol or a Regexp'
        end
        keys
      end

    end

    class ValidationError < StandardError
    end

  end
end
