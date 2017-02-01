# Design Thoughts

This is to explain our design thoughts for anyone that's interested, although it's mainly to remind ourselves in the future ;)

## Rake Tasks

### Project Tasks

The rspec rake tasks are structured on the basis that each module in a project (ignoring external modules for now) has its own set of rspec tests.

We could fix the issues with the main `rspec` task by changing it to scan all modules' spec directories for spec files and run them:

```ruby
RSpec::Core::RakeTask.new :rspec do |t|
    t.pattern = "#{module_path}/**/#{RSpec::Core::RakeTask::DEFAULT_PATTERN}"
end
```

However that means that we need a toplevel project `spec_helper` file, and there could be other issues as well (I'm not an rspec expert).

Another option would be to move all module specs into one project `spec` directory, 
however (putting aside potential `rspec-puppet` file structure issues) having all specs for all modules in one directory could make tests hard to isolate, 
and it will make it hard to separate a module into it's own repo in the future.
