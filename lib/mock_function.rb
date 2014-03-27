require 'puppet'
require 'mocha'

module RSpecPuppetUtils

  class MockFunction

    def initialize(name, options = {})
      parse_options! options
      this = self
      Puppet::Parser::Functions.newfunction(name.to_sym, options) { |args| this.call args}
      yield self if block_given?

      if options[:type] == :statement
        # call is called on statement function incase expects(:call) is needed
        # The method is defined incase expects(:call) isn't used
        def this.call args
          args
        end
      end
    end

    def stub
      self.stubs(:call)
    end

    def expect
      self.expects(:call)
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
