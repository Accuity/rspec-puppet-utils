require 'spec_helper'
require 'lib/hieradata/validator'

module HieraData
  class Test < Validator
    def load
      @data = {
          :file1 => {
              'key' => 'value',
              :other => 'other value',
              'missmatch' => 'string'
          },
          :file2 => {
              'hello' => 'world',
              'missmatch' => ['array']
          }
      }
    end
    def load_empty
      @data = {}
    end
  end
end

describe HieraData::Validator do

  validator = HieraData::Test.new
  validator.load

  it 'should have public data variable' do
    expect(validator.data).to have_key :file1
  end

  it 'should use block to validate key' do
    expect {
      validator.validate?('key') { |v| v == 'value' }
    }.to_not raise_error

    expect {
      validator.validate?('key') { |v| v == 'oooops' }
    }.to raise_error StandardError, /Key key is not valid in file/
  end

  it 'should accept symbol as key' do
    expect {
      validator.validate?(:other) { |v| v == 'other value' }
    }.to_not raise_error
  end

  it 'should validate key in all files' do
    expect {
      validator.validate?('missmatch') { |v| v.is_a? String }
    }.to raise_error StandardError, /Key missmatch is not valid in file file2/
  end

  it 'should raise error if data is nil' do
    nil_validator = HieraData::Test.new
    expect {
      nil_validator.validate?('meh') { }
    }.to raise_error StandardError, /@data is nil, try load\(\) first/
  end

  it 'should raise error if data is empty' do
    empty_validator = HieraData::Test.new
    empty_validator.load_empty
    expect {
      empty_validator.validate?('meh') { }
    }.to raise_error StandardError, /@data is empty/
  end

end
