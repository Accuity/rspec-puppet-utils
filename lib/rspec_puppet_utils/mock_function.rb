require 'puppet'
require 'mocha/api'

module RSpec::Puppet
  module Support
    def self.clear_cache
      begin
        # Cache is a separate class since rspec-puppet 2.3.0
        require 'rspec-puppet/cache'
        @@cache = RSpec::Puppet::Cache.new
      rescue Gem::LoadError
        @@cache = {}
      end
    end
  end
end

module RSpecPuppetUtils

  class MockFunction

    def initialize(name, options = {})
      parse_options! options
      this = self
      Puppet::Parser::Functions.newfunction(name.to_sym, options) { |args| this.call args }
      yield self if block_given?
    end

    def call(args)
      execute *args
    end

    def execute(*args)
      args
    end

    def stubbed
      self.stubs(:execute)
    end

    def expected(*args)
      RSpec::Puppet::Support.clear_cache unless args.include? :keep_cache
      self.expects(:execute)
    end

    # Use stubbed instead, see readme
    def stub
      self.stubs(:call)
    end

    # Use expected instead, see readme
    def expect(*args)
      RSpec::Puppet::Support.clear_cache unless args.include? :keep_cache
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
