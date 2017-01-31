require 'spec_helper'
require 'lib/rspec_puppet_utils/mock_function'

include RSpecPuppetUtils

describe MockFunction do

  let(:scope) { PuppetlabsSpec::PuppetInternals.scope }

  let(:values_from_let) { [1, 2, 3] }

  describe '#initialize' do

    func_name = 'my_func'
    func_sym  = func_name.to_sym

    it 'adds new function to puppet' do
      name = 'mock_func'
      func = MockFunction.new name
      expect(Puppet::Parser::Functions.function(name.to_sym)).to eq "function_#{name}"
    end

    it 'defaults to :rvalue type' do
      func = MockFunction.new func_name
      expect(Puppet::Parser::Functions.rvalue?(func_sym)).to eq true
    end

    it 'defaults to :rvalue type if missing from options' do
      func = MockFunction.new func_name, {}
      expect(Puppet::Parser::Functions.rvalue?(func_sym)).to eq true
    end

    it 'allows type to be set' do
      func = MockFunction.new func_name, {:type => :statement}
      expect(Puppet::Parser::Functions.rvalue?(func_sym)).to eq false
    end

    it 'only allows :rvalue or :statement for type' do
      expect {
        MockFunction.new func_name, {:type => :error}
      }.to raise_error ArgumentError, 'Type should be :rvalue or :statement, not error'
    end

    it 'allows arity to be set' do
      func = MockFunction.new func_name, {:arity => 3}
      expect(Puppet::Parser::Functions.arity(func_sym)).to eq 3
    end

    it 'only allows arity to be an integer' do
      expect {
        MockFunction.new func_name, {:arity => 'oops'}
      }.to raise_error ArgumentError, 'arity should be an integer'
    end

  end

  describe '#call' do

    let(:func) { MockFunction.new('func') }

    it 'is stubable' do
      func.stubs(:call)
      expect(func.respond_to?(:call)).to eq true
    end

    it 'is called by puppet function' do
      func.stubs(:call).returns('penguin')
      result = scope.function_func []
      expect(result).to eq 'penguin'
    end

    it 'is passed puppet function args' do
      func.expects(:call).with([1, 2, 3]).once
      scope.function_func [1, 2, 3]
    end

    it 'passes function args to execute method' do
      func.expects(:execute).with(1, 2, 3)
      func.call [1, 2, 3]
    end

  end

  describe '#stubbed' do

    let(:func) { MockFunction.new('func') }

    it 'stubs #execute' do
      expectation = func.stubbed
      expect(expectation).to be_a Mocha::Expectation
      expect(expectation.matches_method? :execute).to eq true
    end

  end

  describe '#expected' do

    let(:func) { MockFunction.new('func') }

    it 'registers expect on #execute' do
      expectation = func.expected
      expect(expectation).to be_a Mocha::Expectation
      expect(expectation.matches_method? :execute).to eq true
      func.execute # satisfy the expect we just created on #execute!
    end

    it 'clears rspec puppet cache' do
      RSpec::Puppet::Support.expects(:clear_cache).once
      func.expected
      func.execute # satisfy the expect we just created on #execute!
    end

    it 'works with parameter matchers' do
      func.expected.with(regexp_matches(/thing/), anything)
      scope.function_func ['something', 1234]
    end

    context 'when :keep_cache is set' do

      it 'does not clear rspec puppet cache' do
        RSpec::Puppet::Support.expects(:clear_cache).never
        func.expected(:keep_cache)
        func.execute # satisfy the expect we just created on #execute!
      end

    end

  end

  describe '#stub' do

    let(:func) { MockFunction.new('func') }

    it 'stubs #call' do
      expectation = func.stub
      expect(expectation).to be_a Mocha::Expectation
      expect(expectation.matches_method? :call).to eq true
    end

  end

  describe '#expect' do

    let(:func) { MockFunction.new('func') }

    it 'registers expect on #call' do
      expectation = func.expect
      expect(expectation).to be_a Mocha::Expectation
      expect(expectation.matches_method? :call).to eq true
      func.call [nil] # satisfy the expect we just created on #call!
    end

    it 'clears rspec puppet cache' do
      RSpec::Puppet::Support.expects(:clear_cache).once
      func.expect
      func.call [nil] # satisfy the expect we just created on #call!
    end

    context 'when :keep_cache is set' do

      it 'does not clear rspec puppet cache' do
        RSpec::Puppet::Support.expects(:clear_cache).never
        func.expect(:keep_cache)
        func.call [nil] # satisfy the expect we just created on #call!
      end

    end

  end

  context 'when :type => :statement' do

    let!(:statement) { MockFunction.new 'statement', {:type => :statement} }

    it 'does not raise error' do
      expect {
        scope.function_statement []
      }.to_not raise_error
    end

    it 'responds to #call' do
      expect(statement.respond_to? :call).to eq true
    end

  end

  context 'when :type => :rvalue' do

    it 'allows setup stubs' do
      func = MockFunction.new('func') { |f| f.stubs(:call).returns('badger') }
      result = func.call
      expect(result).to eq 'badger'
    end

    it 'returns values defined by a "let"' do
      result = []
      expect {
        func = MockFunction.new('func') { |f| f.stubs(:call).returns(values_from_let) }
        result = func.call
      }.to_not raise_error
      expect(result).to eq [1, 2, 3]
    end

  end

end
