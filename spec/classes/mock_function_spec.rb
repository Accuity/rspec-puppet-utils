require 'spec_helper'
require 'rspec-puppet-utils'

describe MockFunction do

  let(:scope) { PuppetlabsSpec::PuppetInternals.scope }

  context 'with no options' do

    func = MockFunction.new(self, 'func')

    it 'should return an object' do
      expect(func).to_not eq nil
    end

    it 'should not attach stub method to object' do
      expect { func.call 'a' }.to raise_error NoMethodError
    end

    it 'should set function_type to :rvalue' do
      expect(func.function_type).to eq :rvalue
    end

  end

  context 'with options set to nil' do

    it 'should not throw error creating function' do
      expect { MockFunction.new(example.example_group, 'nil_options', nil) }.to_not raise_error
    end

  end

  context 'with a default value of true' do

    default_of_true = MockFunction.new(self, 'default_of_true', {:default_value => true})

    it 'function should return true' do
      expect(default_of_true.call 'a').to eq true
    end

  end

  context 'with a default value of nil' do

    default_of_nil = MockFunction.new(self, 'default_of_nil', {:default_value => nil})

    it 'function should return true' do
      expect(default_of_nil.call 'a').to eq nil
    end

  end

  context 'with a type of :statement' do

    statement = MockFunction.new(self, 'statement', {:type => :statement})

    it 'should set function_type to :statement' do
      expect(statement.function_type).to eq :statement
    end

    it 'should wire up a stub call method' do
      expect { statement.call }.to_not raise_error
    end

  end

  context 'when using a puppet scope' do

    func = MockFunction.new(self, 'func', {:default_value => true})

    it 'puppet should be able to call function' do
      result = scope.function_func ['a']
      expect(result).to eq true
    end

    it 'should be able to stub calls' do
      func.stubs(:call).with([1, 2]).returns(3)
      result = scope.function_func [1, 2]
      expect(result).to eq 3
    end

  end

end
