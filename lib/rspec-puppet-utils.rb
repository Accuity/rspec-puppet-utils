require 'rspec-puppet'
require 'mocha'
require 'erb'

RSpec.configure do |c|
  c.mock_with :mocha
end

class MockFunction

  attr_accessor :function_type, :has_default_value, :default_value

  def initialize(example_group, name, options = {})
    opts = options.nil? ? {} : options

    @function_type = opts.has_key?(:type) ? opts[:type] : :rvalue

    opts[:default_value] = nil if @function_type == :statement

    @has_default_value = false
    if opts.has_key?(:default_value)
      @has_default_value = true
      @default_value = opts[:default_value]
    end

    this = self
    example_group.before(:each) {
      Puppet::Parser::Functions.newfunction(name.to_sym, {:type => this.function_type}) { |args| this.call(args) }
      this.stubs(:call).returns(this.default_value) if this.has_default_value
    }
  end
end

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
    template = File.exists?(@template) ? File.new(@template).read : @template
    ERB.new(template, 0, '-').result b
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
