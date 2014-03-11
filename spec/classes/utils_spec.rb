require 'spec_helper'
require 'rspec-puppet-utils'

describe 'rspec-puppet-utils' do

  it 'should require MockFunction' do
    expect { MockFunction.class }.to_not raise_error
  end

  it 'should require TemplateHarness' do
    expect { TemplateHarness.class }.to_not raise_error
  end

end
