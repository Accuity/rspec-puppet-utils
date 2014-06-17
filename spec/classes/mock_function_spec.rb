require 'spec_helper'
require 'lib/mock_function'

include RSpecPuppetUtils

describe MockFunction do

  let(:scope) { PuppetlabsSpec::PuppetInternals.scope }

  let(:values_from_let) { [1, 2, 3] }

  describe '#initialize' do

    func_name = 'my_func'
    func_sym  = func_name.to_sym

    it 'should add new function to puppet' do
      name = 'mock_func'
      func = MockFunction.new name
      expect(Puppet::Parser::Functions.function(name.to_sym)).to eq "function_#{name}"
    end

    it 'should default to :rvalue type' do
      func = MockFunction.new func_name
      expect(Puppet::Parser::Functions.rvalue?(func_sym)).to eq true
    end

    it 'should default to :rvalue type if missing from options' do
      func = MockFunction.new func_name, {}
      expect(Puppet::Parser::Functions.rvalue?(func_sym)).to eq true
    end

    it 'should allow type to be set' do
      func = MockFunction.new func_name, {:type => :statement}
      expect(Puppet::Parser::Functions.rvalue?(func_sym)).to eq false
    end

    it 'should only allow :rvalue or :statement for type' do
      expect {
        MockFunction.new func_name, {:type => :error}
      }.to raise_error ArgumentError, 'Type should be :rvalue or :statement, not error'
    end

    it 'should allow arity to be set' do
      func = MockFunction.new func_name, {:arity => 3}
      expect(Puppet::Parser::Functions.arity(func_sym)).to eq 3
    end

    it 'should only allow arity to be an integer' do
      expect {
        MockFunction.new func_name, {:arity => 'oops'}
      }.to raise_error ArgumentError, 'arity should be an integer'
    end

  end

  describe '#call' do

    let(:func) { MockFunction.new('func') }

    it 'should not be defined by default' do
      expect(func.respond_to?(:call)).to eq false
    end

    it 'should be stubable' do
      func.stubs(:call)
      expect(func.respond_to?(:call)).to eq true
    end

    it 'should be called by puppet function' do
      func.stubs(:call).returns('penguin')
      result = scope.function_func []
      expect(result).to eq 'penguin'
    end

    it 'should be passed puppet function args' do
      func.expects(:call).with([1, 2, 3]).once
      scope.function_func [1, 2, 3]
    end

  end

  describe '#stub' do

    let(:func) { MockFunction.new('func') }

    it 'should stub #call' do
      expectation = func.stub
      expect(expectation).to be_a Mocha::Expectation
      expect(expectation.matches_method? :call).to eq true
    end

  end

  describe '#expect' do

    let(:func) { MockFunction.new('func') }

    it 'should register expect on #call' do
      expectation = func.expect
      expect(expectation).to be_a Mocha::Expectation
      expect(expectation.matches_method? :call).to eq true
      func.call [nil] # satisfy the expect we just created on #call!
    end

    it 'should clear rspec puppet cache' do
      RSpec::Puppet::Support.expects(:clear_cache).once
      func.expect
      func.call [nil] # satisfy the expect we just created on #call!
    end

  end

  context 'when :type => :statement' do

    let!(:statement) { MockFunction.new 'statement', {:type => :statement} }

    it 'should not raise error' do
      expect {
        scope.function_statement []
      }.to_not raise_error
    end

    it 'should respond to #call' do
      expect(statement.respond_to? :call).to eq true
    end

  end

  context 'when :type => :rvalue' do

    it 'should allow setup stubs' do
      func = MockFunction.new('func') { |f| f.stubs(:call).returns('badger') }
      result = func.call
      expect(result).to eq 'badger'
    end

    it 'should return values defined by a "let"' do
      result = []
      expect {
        func = MockFunction.new('func') { |f| f.stubs(:call).returns(values_from_let) }
        result = func.call
      }.to_not raise_error
      expect(result).to eq [1, 2, 3]
    end

  end

end
