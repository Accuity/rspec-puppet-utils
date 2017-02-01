# rspec-puppet-utils

This is a more refined version of a previous project about [rspec-puppet unit testing](https://github.com/TomPoulton/rspec-puppet-unit-testing), it provides a class for mocking functions, a harness for testing templates, and a simple tool for testing hiera data files. The motivation for mocking functions etc is provided in that project so I won't go over it here.

See [release notes](../../wiki/Release-Notes) about latest version

## Updates:

#### v3.0.0

The project is now developed against ruby 2.1.0 and so it may not be backwards compatible when running on ruby 1.8.7.

The internal file structure has also changed, which shouldn't affect usage, but it might :) 

#### v2.1.0

The `MockFunction` `#stub` and `#expect` methods have been superseded by `#stubbed` and `#expected` so that you can use parameter matchers. The only difference in usage from previous versions is that the methods take a set of parameters rather than a single array (e.g. `f.expected.with(1, 2, 3)` instead of `f.expect.with([1, 2, 3])`)

The change is backwards compatible so `#stub` and `#expect` are still available and function as before

## Usage

### MockFunction

The basic usage is to create your mock function with `MockFunction.new` and then use `mocha` to stub any particular calls that you need

```ruby
require 'spec_helper'

describe 'foo::bar' do

  let!(:add_stuff) { MockFunction.new('add_stuff') { |f|
      f.stubbed.with(1, 2).returns(3)
    }
  }

  it 'should do something with add_stuff' do
    # Specific stub for this test
    add_stuff.stubbed.with(2, 3).returns(5)
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
  f.stubbed.with('non-ex').raises(Puppet::ParseError.new('Key not found'))
  f.stubbed.with('db-password').returns('password1')
}
```
You handle when the functions are created yourself, e.g. you can assign it to a local variable `func = MockFunction...` create it in a before block `before(:each) do MockFunction... end` or use let `let!(:func) { MockFunction... }`

If you use let, **use `let!()` and not `let()`**, this is because lets are lazy-loaded, so unless you explicitly reference your function in each test, the function won't be created and puppet won't find it. Using `let!` means that the function will be created before every test regardless.

Also if you use `let` when mocking hiera, **you can't use `:hiera` as the name due to conflicts** so you have to do something like `let!(:mock_hiera) { MockFunction.new('hiera') }`

##### Mocha stubs and expects:
`f.stubbed` and `f.expected` are helper methods for `f.stubs(:execute)` and `f.expects(:execute)`

Internally `#expected` will clear the rspec-puppet catalog cache. This is because rspec-puppet will only re-compile the catalog for a test if `:title`, `:params`, or `:facts` are changed. This means that if you setup an expectaion in a test, it might not be satisfied because the catalog was already compiled for a previous test, and so the functions weren't called!

Clearing the cache ensures tests aren't coupled and order dependent. The downside is that the catalog isn't cached and has to be re-compiled which slows down your tests. If you're concerned about performance and you are explicitly changing `:title`, `:params`, or `:facts` for a test, you can keep the cache intact with `f.expected(:keep_cache)`

##### Notes:
- You always stub the `execute` method as that gets called internally
- The `execute` method takes a set of arguments instead of an array of arguments

### MockResource (experimental feature)

I've created a rough version for now just to help myself out, if people find it useful or find bugs, let me know

##### Usage:

To stop your tests dissapearing down a rabbit hole, you can use the rspec-puppet `let(:pre_condition) { ... }` feature to create mock versions of resources that your puppet class depends on. For example:

```puppet
class my_module::my_class {

  include foo::bar
  
  $useful_var = $foo::bar::baz
  
  external_module::complex_type { 'complex thing':
    param_one      => 'one',
    param_two      => 'two',
    required_param => 'important value',
  }
  
  <actual stuff you want to test>
}
```

In the tests for `my_class`, you don't want to use the actual `foo::bar` and `external_module::complex_type` resources because it could be a lot of complex setup code, it can be difficult to test multiple scenarios, and you are by extension testing these other classes (which should have tests of their own)

You can therefore mock these resources by creating fakes that have the same "interface", but empty bodies:
```ruby
let(:pre_condition) { [
    "class foo::bar { $baz = 'a value' }",
    "define external_module::complex_type ( $param_one = 'default', $param_two = undef, $required_param ) {}",
] }
```

This can get quite complex if there are multiple parameters and/or internal variables. `MockResource` is designed to make it easier to mock out these dependencies
```ruby
mock_bar = MockResource.new 'foo::bar', {
    :vars => { :baz => some_var_you_want_to_use_later }
}

mock_complex_type = MockResource.new 'external_module::complex_type', {
    :type => :define,
    :params => {
        :param_one      => 'default',
        :param_two      => :undef,
        :required_param => nil,
    }
}

let(:pre_condition) { [
    mock_bar.render,
    mock_complex_thing.render,
] }
```

Hopefully you spend less time debugging syntax errors in your test strings, and more time writing useful code

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
  validator.load_data :ignore_empty
  # Use load_data without args to catch empty files

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

For more about usage see the [wiki page](../../wiki/Hiera-Data-Validator)

### Setup
- Add `rspec-puppet-utils` to your Gemfile (or use `gem install rspec-puppet-utils`)
- Add `require 'rspec-puppet-utils'` to the top of your `spec_helper`

## Rake Tasks (experimental feature)

`rspec-puppet-utils` also provides helper classes to add common rake tasks to a Puppet project or module.

### Project Tasks

The `Rake::Puppet` class provides tasks that handle testing and building a Puppet project.

##### Usage:

An example `Rakefile` might look like this:

```ruby
require 'rake'
require 'rspec_puppet_utils/rake/project_tasks'

puppet = Rake::Puppet.new
puppet.package_version = '1.0.0'
puppet.load_tasks
```

Running `rake -T` afterwords should show a list of spec and build tasks:

```bash
$ rake -T
rake build            # Build puppet.zip v1.0.0
rake quick_build      # Build puppet.zip v1.0.0 without tests
rake spec             # Run specs in all modules
rake spec:<mod a>     # Run <mod a> module specs
rake spec:<mod b>     # Run <mod b> module specs
...
```

There is an spec task for each module, as well as a main `spec` task that will run all specs in a project.

The `build` task will bundle all Puppet code (modules, hiera data file, environment.conf files, etc) into a .zip file which can then be deployed. 

In the example above `package_version` is set as it's a required field. The other accessible properties are:

- module_path      - The directory containing all the modules to test (default: 'modules')
- excluded_modules - Modules to exclude from rspec testing (default: [])
- package_dir      - Where the puppet zip package will be created (default: 'pkg')
- package_files    - Files and directories to include in the package (default: ['modules', 'modules-lib', 'config/environment.conf'])
- package_version  - The version of the package (e.g. 2.1.0)

##### NB:

The `package_files` list is setup for the modules-lib pattern by default. In this pattern external (e.g. Puppet Forge) modules are installed in a separate 'modules-lib', leaving the 'modules' dir for project modules such as 'components', 'profiles', 'role', etc. 
If you're not using this pattern then just provide a new array for `package_files`.

Running the `build` or `quick_build` tasks will delete any existing builds in the `pkg` directory.
This is so the same build task can be run over and over on a build server (e.g. Jenkins) without filling up the disk.
It also guarantees that the binary at the end of a build was just built, and wasn't left over from a previous build.

##### ToDo:

Currently the `spec` task runs all the `spec::<module>` tasks. If one of these fails then none of the subsequent tasks will run. This isn't ideal!

The zip commands need to be replaced by ruby zip library to avoid shelling out, this helps with support for Windows environments

### Module Tasks

WIP
