require 'erb'

module RSpecPuppetUtils

  class TemplateHarness

    def initialize(template, scope = nil)
      @template = template
      @isolator = Isolator.new(scope)
    end

    def set(name, value)
      var_name = name.start_with?('@') ? name : "@#{name}"
      @isolator.instance_variable_set(var_name, value)
    end

    def run
      b = @isolator.get_binding
      inline = !File.exists?(@template)
      template_string = inline ? @template : File.new(@template).read
      template = ERB.new(template_string, 0, '-')
      template.filename = File.expand_path(@template) unless inline
      template.result b
    end

    class Isolator
      # Isolates the binding so that only the defined set
      # of instance variables are available to erb
      def initialize scope
        @scope = scope
      end
      def get_binding
        scope = @scope
        binding
      end
    end

  end

end
