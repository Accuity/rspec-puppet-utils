module RSpecPuppetUtils

  # MockResource is an experimental feature, API may change!
  # Use at your own risk... although feedback would be helpful :)
  class MockResource

    def initialize(name, resource_definition = {})
      @name = name
      @resource_definition = resource_definition
    end

    def render
      type = @resource_definition[:type] || :class
      vars = join_vars @resource_definition[:vars], "\n"

      if @resource_definition[:params].nil?
        param_section = ''
      else
        params = join_vars @resource_definition[:params], ', '
        param_section = "( #{params} )"
      end

      "#{type} #{@name} #{param_section} { #{vars} }"
    end

    def join_vars(vars, join_string)
      return '' unless vars
      parsed_vars = []
      vars.each { |key, val|
        param = "$#{key}"
        value = normalise_value val
        val ? parsed_vars.push("#{param} = #{value}") : parsed_vars.push(param)
      }
      parsed_vars.join join_string
    end

    def normalise_value(value)
      # If string, wrap with quotes
      value.is_a?(String) ? "'#{value}'" : value
    end

  end
end
