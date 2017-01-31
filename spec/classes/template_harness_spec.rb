require 'spec_helper'
require 'lib/rspec_puppet_utils/template_harness'

include RSpecPuppetUtils

describe TemplateHarness do

  it 'should render template' do
    harness = TemplateHarness.new('<%= "inside template" %>')
    expect(harness.run).to eq 'inside template'
  end

  it 'should handle -%> syntax' do
    harness = TemplateHarness.new('<% animal = "penguin" -%><%= animal %>')
    expect { harness.run }.to_not raise_error
  end

  it 'should provide access to scope' do
    scope = PuppetlabsSpec::PuppetInternals.scope
    scope.stubs(:lookupvar).with('honey').returns('badger')
    harness = TemplateHarness.new('<%= scope.lookupvar("honey") %>', scope)
    expect(harness.run).to eq 'badger'
  end

  it 'should provide access to instance vars' do
    harness = TemplateHarness.new('<%= @foo %>')
    harness.set('@foo', 'bar')
    expect(harness.run).to eq 'bar'
  end

  it 'should add @ to instance vars when missing' do
    harness = TemplateHarness.new('<%= @alice %>')
    harness.set('alice', 'bob')
    expect(harness.run).to eq 'bob'
  end

  it 'should isolate instance vars' do
    harness = TemplateHarness.new('<%= @not_exist %>')
    harness.instance_variable_set('@not_exist', 'pixies')
    expect(harness.run).to eq ''
  end

  it 'should read file if it exists' do
    harness = TemplateHarness.new('spec/fixtures/templates/returns_elephant.erb')
    expect(harness.run).to eq 'elephant'
  end

  it 'should set filename of template' do
    template_path = 'spec/fixtures/templates/returns_elephant.erb'
    absolute_path = File.expand_path(template_path)

    fakeplate = Object.new
    fakeplate.stubs(:result).returns('')
    fakeplate.expects(:filename=).with(absolute_path).once
    ERB.stubs(:new).returns(fakeplate)

    TemplateHarness.new(template_path).run
  end

  it 'should not set filename of inline template' do
    fakeplate = Object.new
    fakeplate.stubs(:result).returns('')
    fakeplate.expects(:filename=).never
    ERB.stubs(:new).returns(fakeplate)

    TemplateHarness.new('<%= "" %>').run
  end

end
