# frozen_string_literal: true

require File.expand_path('lib/mongoid/geospatial/version', __dir__)

Gem::Specification.new do |gem|
  gem.name          = 'mongoid-geospatial'
  gem.version       = Mongoid::Geospatial::VERSION

  gem.authors       = ['Ryan Ong', 'Marcos Piccinini']
  gem.email         = ['use@git.hub.com']
  gem.summary       = 'Mongoid Extension that simplifies MongoDB Geospatial Operations.'
  gem.description   = 'Mongoid Extension that simplifies MongoDB casting and operations on spatial Ruby objects.'
  gem.homepage      = 'https://github.com/mongoid/mongoid-geospatial'
  gem.license       = 'MIT'
  gem.required_ruby_version = Gem::Requirement.new('>= 3.1.0')

  gem.metadata['rubygems_mfa_required'] = 'true'

  # Use Dir.glob to list all files within the lib directory
  gem.files = Dir.glob('lib/**/*') + ['README.md', 'MIT-LICENSE']
  gem.require_paths = ['lib']

  gem.add_dependency('mongoid', ['>= 4.0.0'])
  gem.metadata['rubygems_mfa_required'] = 'true'
end
