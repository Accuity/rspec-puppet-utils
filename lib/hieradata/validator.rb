module RSpecPuppetUtils
  module HieraData
    class Validator

      attr_reader :data

      def validate(key, &block)
        raise StandardError, '@data is nil, try #load first' unless @data
        raise StandardError, '@data is empty' if @data.empty?

        found = false
        @data.keys.each do |file|
          keys = get_matching_keys(key, file)
          keys.each do |matched_key|
            found = true
            begin
              block.call(@data[file][matched_key])
            rescue Exception => e
              raise StandardError, "#{matched_key} is invalid in #{file}: #{e.message}"
            end
          end
        end
        raise StandardError, "No match for #{key.inspect} was not found in any files" unless found
      end

      private

      def get_matching_keys(key, file)
        if key.is_a?(String) || key.is_a?(Symbol)
          keys = @data[file].has_key?(key) ? [key] : []
        elsif key.is_a?(Regexp)
          keys = @data[file].keys.select { |k| k.to_s =~ key }
        else
          raise StandardError, 'Search key must be a String, Symbol or a Regexp'
        end
        keys
      end

    end
  end
end
