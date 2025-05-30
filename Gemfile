source 'https://rubygems.org'

gem 'mongoid'

gemspec

group :development, :test do
  gem 'pry'
  gem 'yard'
  gem 'fuubar'
  gem 'rake'
  gem 'guard'
  gem 'guard-rubocop'
  gem 'guard-rspec'
  gem 'rubocop'
end

group :test do
  gem 'nokogiri'
  gem 'dbf'
  gem 'rgeo'
  gem 'georuby'
  gem 'rspec'
  gem 'coveralls', require: false if ENV['CI']
end
