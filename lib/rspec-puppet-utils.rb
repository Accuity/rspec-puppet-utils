require 'rspec-puppet'
require 'erb'

class MockFunction

  def initialize(name, options = {})
    type_hash = !options.nil? && options.has_key?(:type) ? {:type => options[:type]} : {:type => :rvalue}

    @default_value = options[:default_value] if !options.nil? && options.has_key?(:default_value)

    before(:each) {
      Puppet::Parser::Functions.newfunction(name.to_sym, type_hash) { |args| self.call(args) }
      self.stubs(:call).returns(@default_value) if @default_value
    }
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
