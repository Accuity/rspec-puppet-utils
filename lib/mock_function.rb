require 'puppet'

module RSpecPuppetUtils

  class MockFunction

    def initialize(name, options = {})
      parse_options! options
      if options[:type] == :rvalue
        this = self
        Puppet::Parser::Functions.newfunction(name.to_sym, options) { |args| this.call args}
        yield self if block_given?
      else
        # Even though the puppet function does not return a value,
        # this mock still needs to do something, what it returns doesn't really matter.
        Puppet::Parser::Functions.newfunction(name.to_sym, options) { |args| args }
      end
    end

    private

    def parse_options!(options)
      unless options[:type]
        options[:type] = :rvalue
      end
      unless [:rvalue, :statement].include? options[:type]
        raise ArgumentError, "Type should be :rvalue or :statement, not #{options[:type]}"
      end
      unless options[:arity].nil? || options[:arity].is_a?(Integer)
        raise ArgumentError, 'arity should be an integer'
      end
    end

  end

end
