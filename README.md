# rspec-puppet-utils

This is the continuation of a previous project about [rspec-puppet unit testing](https://github.com/TomPoulton/rspec-puppet-unit-testing), it provides a more refined version of the helper method for mocking functions, plus a harness for testing templates. The motivation for mocking functions etc is provided there so I won't go over it here.

## Usage

### MockFunction

The basic usage is to create your mock function with `MockFunction.new` and then use `mocha` to stub any particular calls that you need

```ruby
require 'spec_helper'

describe 'foo::bar' do

  add_stuff = MockFunction.new(self, 'add_stuff')
  before(:each) do
    add_stuff.stubs(:call).with([1, 2]).returns(3)
  end

  it 'should do something with add_stuff' do
    ...
  end
end
```

You can specify a default value:
```ruby
func = MockFunction.new(self, 'func', {:default_value => true})
```

You can mock a function that doesn't return a value (`:rvalue` is the default):
```ruby
func = MockFunction.new(self, 'func', {:type => :statement})
```

You can mock Hiera:
```ruby
hiera = MockFunction.new(self, 'hiera')
before(:each) do
  hiera.stubs(:call).with(['non-ex']).raises(Puppet::ParseError.new('Key not found'))
  hiera.stubs(:call).with(['db-password']).returns('password1')
end
```

Note:
- You always stub the `call` method as that gets called internally
- The `call` method takes an array of arguments
- `self` is a way of getting hold of the current `RSpec::Core::ExampleGroup` instance. If anyone knows how to do this more cleanly let me know!

### TemplateHarness

If your templates have some logic in them that you want to test, and you'd ideally like to get hold of the generated template so you can inspect it programatically rather than just using a regex then use `TemplateHarness`

Given a basic template:


```ruby
<%
    from_class = @class_var
    from_fact  = scope.lookupvar('fact-name')
    from_hiera = scope.function_hiera('hiera-key')
-%>
<%= "#{from_class} #{from_fact} #{from_hiera}" %>

```

A test could look like this:


```ruby
require 'spec_helper'

describe 'my_template' do

  let(:scope) { PuppetlabsSpec::PuppetInternals.scope }
  before(:each) do
    scope.stubs(:lookupvar).with('fact-name').returns('fact-value')
    scope.stubs(:function_hiera).with('hiera-key').returns('hiera-value')
  end
  
  it 'should render template' do
    harness = TemplateHarness.new('spec/.../.../my_template.erb', scope)
    harness.set('@class_var', 'classy')
    result = harness.run
    expect(result).to eq 'classy fact-value hiera-value'
  end

end
```

Note:
- The path resolution is pretty simple, just pass it a normal relative path, **not** like the paths you pass into the `template` function in puppet (where you expect puppet to add the `templates` section to the path)

## Setup
- Add `rspec-puppet-utils` to your Gemfile (or use `gem install rspec-puppet-utils`)
- Add `require 'rspec-puppet-utils'` to the top of your `spec_helper`
