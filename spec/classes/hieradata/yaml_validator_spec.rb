require 'spec_helper'
require 'lib/rspec_puppet_utils/hieradata/yaml_validator'

include RSpecPuppetUtils

describe HieraData::YamlValidator do

  it 'should be of type Validator' do
    validator = HieraData::YamlValidator.new('spec/fixtures/hieradata/valid')
    expect(validator).to be_a_kind_of HieraData::Validator
  end

  describe '#load_data' do

    context 'with valid yaml' do

      validator = HieraData::YamlValidator.new('spec/fixtures/hieradata/valid')
      validator.load_data

      it 'should load yaml files into data' do
        expect(validator.data.keys.size).to_not be 0
      end

      it 'should load yaml files recursively' do
        expect(validator.data.keys).to include :'sub/nested.yaml'
      end

      it 'should load yaml data from files' do
        expect(validator.data[:'valid.yaml']['string-value']).to eq 'a string'
      end

      it 'should load yaml data from files with dot in filename' do
        expect(validator.data.keys).to include :'sub/nested.dot.yaml'
      end

      it 'should load yaml data from files with same name but different dir' do
        expect(validator.data.keys).to include :'sub2/nested.dot.yaml'
      end

      it 'should load yaml data from files with same name but different ext' do
        expect(validator.data.keys).to include :'sub2/nested.dot.yml'
      end

      it 'should not add any load errors' do
        expect(validator.load_errors).to be_an Array
        expect(validator.load_errors).to be_empty
      end

    end

    context 'with multiple extensions' do

      validator = HieraData::YamlValidator.new('spec/fixtures/hieradata/valid', ['yaml', 'foo'])
      validator.load_data

      it 'should load yml files into data' do
        expect(validator.data).to have_key :'other.foo'
      end

    end

    context 'with extensions as string' do

      it 'should load yml files into data' do
        expect { HieraData::YamlValidator.new('meh', 'whooops') }.to raise_error ArgumentError, /extensions should be an Array/
      end

    end

    context 'with invalid yaml' do

      validator = HieraData::YamlValidator.new('spec/fixtures/hieradata/invalid')

      it 'should not raise error' do
        expect {
          validator.load_data
        }.to_not raise_error
      end

      it 'should add error to load_errors' do
        expect(validator.load_errors).to be_an Array
        expect(validator.load_errors.size).to eq 1
        expect(validator.load_errors[0]).to match /Error in file .*\/invalid.yaml/
      end

    end

    context 'with empty yaml' do

      subject(:validator) { HieraData::YamlValidator.new('spec/fixtures/hieradata/empty') }

      it 'should not raise error by default' do
        expect {
          validator.load_data
        }.to_not raise_error # /Yaml file is empty: .*\/empty.yaml/
      end

      it 'should add error to load_errors' do
        validator.load_data
        expect(validator.load_errors).to be_an Array
        expect(validator.load_errors.size).to eq 1
        expect(validator.load_errors[0]).to match /Yaml file is empty: .*\/empty.yaml/
      end

      it 'should ignore empty files when flag is set' do
        expect { validator.load_data :ignore_empty }.to_not raise_error
      end

      it 'should not add empty files to @data' do
        validator.load_data :ignore_empty
        expect(validator.data.keys).to_not include :empty
      end

      it 'should add non empty files to data' do
        validator.load_data :ignore_empty
        expect(validator.data.keys).to include :'not_empty.yaml'
      end

    end

    it 'should return validator instance' do
      validator = HieraData::YamlValidator.new('spec/fixtures/hieradata/valid')
      expect(validator.load_data).to eq validator
    end

  end

  describe '#load' do

    subject(:validator) { HieraData::YamlValidator.new('spec/fixtures/hieradata/empty') }
    before(:each) do
      validator.stubs(:warn) # Hide warn message from output
    end

    it 'should support old #load method' do
      expect { validator.load true }.to_not raise_error
      expect(validator.data.keys).to include :'not_empty.yaml'
    end

    it 'should still throw errors if necessary' do
      expect {
        validator.load
      }.to raise_error HieraData::ValidationError
    end

    it 'should warn when using old #load method' do
      validator.expects(:warn).with('#load is deprecated, use #load_data instead').once
      validator.load true
    end

  end

end
