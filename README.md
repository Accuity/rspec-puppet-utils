# rspec-puppet-utils

This is a more refined version of a previous project about [rspec-puppet unit testing](https://github.com/TomPoulton/rspec-puppet-unit-testing), it provides a class for mocking functions, a harness for testing templates, and a simple tool for testing hiera data files. The motivation for mocking functions etc is provided in that project so I won't go over it here.

See [release notes for v2.0.1](../../wiki/Release-Notes#v201)

## Usage

### MockFunction

The basic usage is to create your mock function with `MockFunction.new` and then use `mocha` to stub any particular calls that you need

```ruby
require 'spec_helper'

describe 'foo::bar' do

  let!(:add_stuff) { MockFunction.new('add_stuff') { |f|
      f.stubs(:call).with([1, 2]).returns(3)
    }
  }

  it 'should do something with add_stuff' do
    # Specific stub for this test
    add_stuff.stubs(:call).with([]).returns(nil)
    ...
  end
end
```

You can mock a function that doesn't return a value (`:rvalue` is the default):
```ruby
MockFunction.new('func', {:type => :statement})
```

You can mock Hiera:
```ruby
MockFunction.new('hiera') { |f|
  f.stubs(:call).with(['non-ex']).raises(Puppet::ParseError.new('Key not found'))
  f.stubs(:call).with(['db-password']).returns('password1')
}
```
You handle when the functions are created yourself, e.g. you can assign it to a local variable `func = MockFunction...` create it in a before block `before(:each) do MockFunction... end` or use let `let!(:func) { MockFunction... }`

If you use let, **use `let!()` and not `let()`**, this is because lets are lazy-loaded, so unless you explicitly reference your function in each test, the function won't be created and puppet won't find it. Using `let!` means that the function will be created before every test regardless.

Also if you use `let` when mocking hiera, **you can't use `:hiera` as the name due to conflicts** so you have to do something like `let!(:mock_hiera) { MockFunction.new('hiera') }`

Notes:
- You always stub the `call` method as that gets called internally
- The `call` method takes an array of arguments

### TemplateHarness

If your templates have some logic in them that you want to test, you'd ideally like to get hold of the generated template so you can inspect it programmatically rather than just using a regex. In this case use `TemplateHarness`

Given a basic template:


```erb
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
 
### HieraData::Validator

The motivation behind this is to quickly check that your hiera data files have no syntax errors without having to run all of the possible combinations of your hiera hierarchy. At the moment this only supports yaml, but other file types can be added easily.

```ruby
require 'spec_helper'

describe 'YAML hieradata' do

  # Files are loaded recursively
  validator = HieraData::YamlValidator.new('spec/fixtures/hieradata')

  it 'should not contain syntax errors' do
    # Use true to ignore empty files (default false)
    expect { validator.load true }.to_not raise_error
  end

  context 'with valid yaml' do

    validator.load true

    # Check types
    it 'should use arrays for api host lists' do
      validator.validate('my-api-hosts') { |v|
        expect(v).to be_an Array
      }
    end

    # Use regex to match keys
    it 'ports should only contain digits' do
      validator.validate(/-port$/) { |v|
        expect(v).to match /^[0-9]+$/
      }
    end

    # Supply a list of files that the key must be in
    # (all matches in all other files are still validated)
    # :live and :qa correspond to live.yaml and qa.yaml
    it 'should override password in live and qa' do
      validator.validate('password', [:live, :qa]) { |v|
        expect ...
      }
    end

  end

end
```

In the examples above all keys in all yaml files are searched and checked

If there is an error, you'll see the inner RSpec error, as well as which key and which file is incorrect:

```
RSpecPuppetUtils::HieraData::ValidationError: mail-smtp-port is invalid in live: expected "TwoFive" to match /^[0-9]+$/
Diff:
@@ -1,2 +1,2 @@
-/^[0-9]+$/
+"TwoFive"
```

## Setup
- Add `rspec-puppet-utils` to your Gemfile (or use `gem install rspec-puppet-utils`)
- Add `require 'rspec-puppet-utils'` to the top of your `spec_helper`
