require 'rspec-puppet'

module RSpecPuppetUtils

  class MockFunction

    def initialize(name, options = {}, &block)
      parse_options! options
      this = self
      Puppet::Parser::Functions.newfunction(name.to_sym, options) { |args| this.call args }
      instance_eval(&block) if block
    end

    private

    def parse_options! options
      options[:type] = :rvalue unless options[:type]
      if options[:type] != :rvalue && options[:type] != :statement
        raise ArgumentError, "Type should be :rvalue or :statement, not #{options[:type]}"
      end
      if options[:arity] && !options[:arity].is_a?(Integer)
        raise ArgumentError, 'arity should be an integer'
      end
    end

  end

end
