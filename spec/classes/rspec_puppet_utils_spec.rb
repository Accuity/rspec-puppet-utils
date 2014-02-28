require 'spec_helper'

describe 'rspec-puppet-utils' do

  describe 'MockFunction' do

    it 'should create a new object' do
      func = MockFunction.new('mock')
      expect(func).to_not eq nil
    end

  end

end
