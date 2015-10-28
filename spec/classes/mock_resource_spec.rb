require 'spec_helper'
require 'lib/mock_resource'

include RSpecPuppetUtils

describe MockResource do

  let(:resource_name) { 'my_mock_resource' }
  let(:resource_definition) {
    {
        :params => {
            :string_param => 'hello',
            :undef_param => :undef,
            :required_param => nil,
        },
        :vars => {
            :my_var_one => 'uno',
            :my_var_two => 2,
        }
    }
  }

  describe 'render' do

    subject(:mock_resource) { MockResource.new(resource_name, resource_definition).render }

    it 'returns the rendered resource' do
      expect(mock_resource).to match /class .* \{/
    end

    it 'adds the name to the resource' do
      expect(mock_resource).to match /class #{resource_name}/
    end

    it 'renders string params in quotes' do
      expect(mock_resource).to match /\(.*\$string_param = 'hello'.*\)/
    end

    it 'renders undef params without quotes' do
      expect(mock_resource).to match /\(.*\$undef_param = undef.*\)/
    end

    it 'renders required params without an assigned value' do
      expect(mock_resource).to match /\(.*\$required_param(,.*|\s*\))/
    end

    it 'renders string variables with quotes' do
      expect(mock_resource).to match /\{.*\$my_var_one = 'uno'.*\}/m
    end

    it 'renders numerical variables without quotes' do
      expect(mock_resource).to match /\{.*\$my_var_two = 2.*\}/m
    end

    context 'when no params are provided' do

      before :each do
        resource_definition.delete :params
      end

      it 'renders no parenthesis' do
        expect(mock_resource).to match /#{resource_name}\s+\{.*\}/m
      end

    end

    context 'when type is :define' do

      before :each do
        resource_definition[:type] = :define
      end

      it 'renders a defined type' do
        expect(mock_resource).to match /define #{resource_name}/
      end

    end

  end

end
