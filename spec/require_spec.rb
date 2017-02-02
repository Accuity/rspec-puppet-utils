require 'lib/rspec_puppet_utils/mock_function'

describe 'requires' do
  it 'requires mocha properly without the spec_helper' do
    Puppet::Parser::Functions.reset
    func = RSpecPuppetUtils::MockFunction.new 'func'
    expect { func.stubbed }.not_to raise_error
  end
end
