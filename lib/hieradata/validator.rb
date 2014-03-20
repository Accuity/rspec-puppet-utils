module RSpecPuppetUtils
  module HieraData

    class Validator

      attr_reader :data

      def validate(key, required=[],&block)
        raise ValidationError, 'No data available, try #load first' if @data.nil? || @data.empty?
        raise ArgumentError, "required should be of type Array" unless required.nil? || required.is_a?(Array)
        required_list = required.dup

        @found = false
        @data.keys.each do |file|
          validate_file(file,key,required_list,&block)
        end
        raise ValidationError, "No match for #{key.inspect} was not found in any files" unless @found
        raise KeyRequireError, "Key not found in required file" unless required_list.empty?
      end


      def validate_file(file, key, required = [], &block)
        keys = get_matching_keys(key, file)
        keys.each do |matched_key|
          @found = true
          begin
            required.delete file
            block.call(@data[file][matched_key])
          rescue Exception => e
            raise ValidationError, "#{matched_key} is invalid in #{file}: #{e.message}"
          end
        end
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

    class KeyRequireError < StandardError
    end
    class ValidationError < StandardError
    end

  end
end