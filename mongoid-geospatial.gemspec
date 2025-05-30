require File.expand_path('lib/mongoid/geospatial/version', __dir__)

Gem::Specification.new do |gem|
  gem.authors       = ['Ryan Ong', 'Marcos Piccinini']
  gem.email         = ['use@git.hub.com']
  gem.summary       = 'Mongoid Extension that simplifies MongoDB Geospatial Operations.'
  gem.description   = 'Mongoid Extension that simplifies MongoDB casting and operations on spatial Ruby objects.'
  gem.homepage      = 'https://github.com/mongoid/mongoid-geospatial'

  gem.files         = `git ls-files`.split("\n")
  gem.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  gem.name          = 'mongoid-geospatial'
  gem.require_paths = ['lib']
  gem.version       = Mongoid::Geospatial::VERSION
  gem.license       = 'MIT'

  gem.add_dependency('mongoid', ['>= 4.0.0'])
end
