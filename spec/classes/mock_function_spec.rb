require 'spec_helper'
require 'rspec-puppet-utils'

describe MockFunction do

  # Each MockFunction must be created here and each test defined within a context
  # otherwise the stubbed default method is not attached
  # (i.e. the before(:each) block in MockFunction isn't run)

  func = MockFunction.new('func')
  default_of_nil = MockFunction.new('default_of_nil', {:default_value => nil})
  default_of_true = MockFunction.new('default_of_true', {:default_value => true})
  statement = MockFunction.new('statement', {:type => :statement})

  let(:scope) { PuppetlabsSpec::PuppetInternals.scope }

  context 'with no options' do

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
      expect { MockFunction.new('nil_options', nil) }.to_not raise_error
    end

  end

  context 'with a default value of true' do

    it 'function should return true' do
      expect(default_of_true.call 'a').to eq true
    end

  end

  context 'with a default value of nil' do

    it 'function should return true' do
      expect(default_of_nil.call 'a').to eq nil
    end

  end

  context 'with a type of :statement' do

    it 'should set function_type to :statement' do
      expect(statement.function_type).to eq :statement
    end

    it 'should wire up a stub call method' do
      expect { statement.call }.to_not raise_error
    end

  end

  context 'when using a puppet scope' do

    it 'puppet should be able to call function' do
      result = scope.function_default_of_true ['a']
      expect(result).to eq true
    end

    it 'should be able to stub calls' do
      func.stubs(:call).with([1, 2]).returns(3)
      result = scope.function_func [1, 2]
      expect(result).to eq 3
    end

  end

end
