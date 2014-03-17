require 'lib/hieradata/yaml_validator'

include RSpecPuppetUtils

describe HieraData::YamlValidator do

  it 'should be of type Validator' do
    validator = HieraData::YamlValidator.new('spec/fixtures/hieradata/valid')
    expect(validator).to be_a_kind_of HieraData::Validator
  end

  context 'with valid yaml' do

    validator = HieraData::YamlValidator.new('spec/fixtures/hieradata/valid')
    validator.load

    it 'should load yaml files into data' do
      expect(validator.data.keys.size).to_not be 0
    end

    it 'should load yaml files recursively' do
      expect(validator.data.keys).to include :nested
    end

    it 'should load yaml data from files' do
      expect(validator.data[:valid]['string-value']).to eq 'a string'
    end

  end

  context 'with multiple extensions' do

    validator = HieraData::YamlValidator.new('spec/fixtures/hieradata/valid', ['yaml', 'foo'])
    validator.load

    it 'should load yml files into data' do
      expect(validator.data).to have_key :other
    end

  end

  context 'with extensions as string' do

    it 'should load yml files into data' do
      expect { HieraData::YamlValidator.new('meh', 'whooops') }.to raise_error ArgumentError, /extensions should be an Array/
    end

  end

  context 'with invalid yaml' do

    validator = HieraData::YamlValidator.new('spec/fixtures/hieradata/invalid')

    it 'should raise error with syntax error' do
      expect { validator.load }.to raise_error StandardError, /Yaml Syntax error in file .*\/invalid.yaml/
    end

  end

  context 'with empty yaml' do

    validator = HieraData::YamlValidator.new('spec/fixtures/hieradata/empty')

    it 'should raise error' do
      expect { validator.load }.to raise_error StandardError, /Yaml file is empty: .*\/empty.yaml/
    end

    it 'should ignore empty files when flag is set' do
      expect { validator.load true }.to_not raise_error
    end

  end

end
