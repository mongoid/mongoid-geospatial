# frozen_string_literal: true

source 'https://rubygems.org'

version = ENV['MONGOID_VERSION'] || '9'
gem 'json', '< 3' # ActiveSupport before 8.1 passes the removed quirks_mode option.
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
  gem 'simplecov', '~> 0.22', require: false if ENV['COVERAGE'] == 'true'
end
