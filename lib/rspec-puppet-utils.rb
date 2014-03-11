require 'rspec'
require 'mocha'
require 'mock_function'
require 'template_harness'
require 'hieradata/validator'
require 'hieradata/yaml_validator'

RSpec.configure do |c|
  c.mock_with :mocha
end
