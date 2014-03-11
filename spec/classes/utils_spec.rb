require 'spec_helper'
require 'rspec-puppet-utils'

describe 'rspec-puppet-utils' do

  it 'should require MockFunction' do
    expect { MockFunction.class }.to_not raise_error
  end

  it 'should require TemplateHarness' do
    expect { TemplateHarness.class }.to_not raise_error
  end

  it 'should require HieraData Validator' do
    expect { HieraData::Validator.class }.to_not raise_error
  end

  it 'should require HieraData YamlValidator' do
    expect { HieraData::YamlValidator.class }.to_not raise_error
  end

end
