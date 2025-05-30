source 'https://rubygems.org'

gem 'mongoid'

gemspec

group :development, :test do
  gem 'fuubar'
  gem 'rake'
  gem 'guard'
  gem 'guard-rspec'
  gem 'rubocop'
end

group :test do
  gem 'coveralls', require: false if ENV['CI']
end
