require 'rspec-puppet'
require 'puppetlabs_spec_helper/module_spec_helper'

$LOAD_PATH.unshift '.'

RSpec.configure do |c|
  c.color = true
end