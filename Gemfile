# frozen_string_literal: true

source 'https://rubygems.org'

gem 'mongoid'

gemspec

group :development, :test do
  gem 'bigdecimal'
  gem 'fuubar'
  gem 'georuby'
  gem 'guard'
  gem 'guard-rspec'
  gem 'guard-rubocop'
  gem 'rake'
  gem 'reline'
  gem 'rgeo'
  gem 'rubocop'
end

group :test do
  gem 'coveralls', require: false if ENV['CI']
end
