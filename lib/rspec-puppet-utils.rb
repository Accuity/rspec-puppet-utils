require 'rspec'
require 'mocha'
require 'lib/mock_function'
require 'lib/template_harness'
require 'lib/hieradata/validator'
require 'lib/hieradata/yaml_validator'

RSpec.configure do |c|
  c.mock_with :mocha
end
