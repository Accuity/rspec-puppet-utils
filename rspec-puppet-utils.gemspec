# -*- encoding: utf-8 -*-
Gem::Specification.new do |gem|
  gem.name          = 'rspec-puppet-utils'
  gem.version       = '2.2.1'
  gem.description   = 'Helper classes for mock/stub functions, templates and hierdata'
  gem.summary       = ''
  gem.author        = 'Tom Poulton'
  #gem.license       = ''

  gem.homepage      = 'https://github.com/Accuity/rspec-puppet-utils'
  gem.files         = `git ls-files`.split($/)
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.require_paths = ['lib']

  gem.add_runtime_dependency 'mocha'
  gem.add_runtime_dependency 'puppet', '~> 3'
  gem.add_runtime_dependency 'puppetlabs_spec_helper'
  gem.add_runtime_dependency 'rspec', '3.1.0'
  gem.add_runtime_dependency 'rspec-puppet'
  gem.add_runtime_dependency 'thor'
end
