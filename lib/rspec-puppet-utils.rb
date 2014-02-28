require 'rspec-puppet'
require 'mocha'
require 'erb'

RSpec.configure do |c|
  c.mock_with :mocha
end

class MockFunction

  attr_accessor :function_type, :has_default_value, :default_value

  def initialize(name, options = {})
    opts = options.nil? ? {} : options

    @function_type = opts.has_key?(:type) ? opts[:type] : :rvalue

    opts[:default_value] = nil if @function_type == :statement

    @has_default_value = false
    if opts.has_key?(:default_value)
      @has_default_value = true
      @default_value = opts[:default_value]
    end

    this = self
    RSpec.configure do |c|
      c.before(:each) {
        Puppet::Parser::Functions.newfunction(name.to_sym, {:type => :rvalue}) { |args| this.call(args) }
        this.stubs(:call).returns(this.default_value) if this.has_default_value
      }
    end
  end
end

class TemplateHelper
  @location
  @scope

  def scope
    @scope
  end

  def set(name,value)
    var_name = name.start_with?('@') ? name : "@#{name}"  # the '@' is required
    self.instance_variable_set(var_name, value)
  end

  def initialize(location, scope)
    @location = location
    @scope = scope
  end

  def output()
    b = binding
    ERB.new('<%= @properties[0][0] %> <%= scope.lookupvar("keys") %> <%= scope.function_hiera(["key"]) %>', 0, '-').result b
  end

end
