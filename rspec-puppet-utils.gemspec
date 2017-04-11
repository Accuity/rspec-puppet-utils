# -*- encoding: utf-8 -*-
Gem::Specification.new do |gem|
  gem.name          = 'rspec-puppet-utils'
  gem.version       = '3.2.0'
  gem.description   = 'Helper classes for mock/stub functions, templates and hieradata'
  gem.summary       = ''
  gem.author        = 'Tom Poulton'
  gem.license       = 'MIT'

  gem.homepage      = 'https://github.com/Accuity/rspec-puppet-utils'
  gem.files         = `git ls-files`.split($/)
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.require_paths = ['lib']

  gem.add_dependency('puppet')
  gem.add_dependency('rspec')
  gem.add_dependency('rspec-puppet')
  gem.add_dependency('puppetlabs_spec_helper')
  gem.add_dependency('mocha')
end
