require 'rspec'
require 'mocha'
require 'lib/mock_function'
require 'lib/template_harness'

RSpec.configure do |c|
  c.mock_with :mocha
end
