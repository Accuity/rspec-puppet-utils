require 'rspec-puppet'

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
