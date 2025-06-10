source 'https://rubygems.org'

gem 'mongoid'

gemspec

group :development, :test do
  gem 'fuubar'
  gem 'rake'
  gem 'guard'
  gem 'guard-rspec'
  gem 'guard-rubocop'
  gem 'rubocop'
  gem 'bigdecimal'
  gem 'georuby'
  gem 'rgeo'
  gem 'reline'
end

group :test do
  gem 'coveralls', require: false if ENV['CI']
end
