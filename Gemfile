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
  gem 'rake'
  gem 'reline'
  gem 'rgeo'
  gem 'yard'
  if RUBY_ENGINE == 'ruby' && Gem::Version.new(RUBY_VERSION) >= Gem::Version.new('3.3')
    gem 'guard-rubocop'
    gem 'rubocop', '~> 1.92'
    gem 'rubocop-md', '~> 3.0', require: false
    gem 'rubocop-prose', '~> 0.2', require: false
    gem 'rubocop-rake', '~> 0.7', require: false
    gem 'rubocop-spellcheck', '~> 0.2', require: false
    gem 'rubocop-yaml', '~> 0.1.0', require: false
  end
end

group :test do
  gem 'simplecov', '~> 0.22', require: false if ENV['COVERAGE'] == 'true'
end
