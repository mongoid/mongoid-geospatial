# frozen_string_literal: true

source 'https://rubygems.org'

version = ENV['MONGOID_VERSION'] || '9'
gem 'logger'
gem 'mongoid', version =~ /\A\d+\z/ ? "~> #{version}.0" : version

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
  gem 'rubocop-rake'
  gem 'yard'
end

group :test do
  gem 'coveralls', require: false if ENV['CI']
end
