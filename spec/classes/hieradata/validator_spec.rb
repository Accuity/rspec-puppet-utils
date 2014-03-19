require 'spec_helper'
require 'lib/hieradata/validator'

include RSpecPuppetUtils

module HieraData
  class Test < Validator
    def load
      @data = {
          :file1 => {
              'key' => 'value',
              :other => 'other value',
              'missmatch' => 'string',
              'cat' => 'black',
          },
          :file2 => {
              'hello' => 'world',
              'missmatch' => ['array'],
              'hat' => 'fedora',
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
      validator.validate('key') { |v| expect(v).to eq 'value' }
    }.to_not raise_error

    expect {
      validator.validate('key') { |v| expect(v).to eq 'oooops' }
    }.to raise_error StandardError
  end

  it 'should accept symbol as key' do
    expect {
      validator.validate(:other) { |v| v == 'other value' }
    }.to_not raise_error
  end

  it 'should validate key in all files' do
    expect {
      validator.validate('missmatch') { |v| expect(v).to be_a String }
    }.to raise_error StandardError
  end

  it 'should return key and file in error messages' do
    expect {
      validator.validate('missmatch') { |v| expect(v).to be_a String }
    }.to raise_error StandardError, /missmatch is invalid in file2/
  end

  context 'when matching with regex' do

    it 'should raise error if no match is found' do
      expect {
        validator.validate(/nonex/) { }
      }.to raise_error StandardError, /No match for \/nonex\/ was not found/
    end

    it 'should not raise error if match is found' do
      expect {
        validator.validate(/at$/) { }
      }.to_not raise_error
    end

    it 'should validate block against all matches' do
      parser = mock()
      parser.expects(:parse).with('black').once
      parser.expects(:parse).with('fedora').once
      validator.validate(/at$/) { |v| parser.parse v }
    end

    it 'should match symbols' do
      expect {
        validator.validate(/other/) { |v| expect(v).to eq 'other value' }
      }.to_not raise_error
    end

  end

  it 'should raise error if data is nil' do
    nil_validator = HieraData::Test.new
    expect {
      nil_validator.validate('meh') { }
    }.to raise_error StandardError, /No data available/
  end

  it 'should raise error if data is empty' do
    empty_validator = HieraData::Test.new
    empty_validator.load_empty
    expect {
      empty_validator.validate('meh') { }
    }.to raise_error StandardError, /No data available/
  end

end
