# frozen_string_literal: true

$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))
$LOAD_PATH.unshift(File.dirname(__FILE__))

MODELS = File.join(File.dirname(__FILE__), 'models')
SUPPORT = File.join(File.dirname(__FILE__), 'support')
$LOAD_PATH.unshift(MODELS)
$LOAD_PATH.unshift(SUPPORT)

if ENV['CI']
  require 'coveralls'
  Coveralls.wear!
end

require 'rspec'
require 'mongoid/geospatial'

Mongoid.load!(File.expand_path('mongoid.yml', __dir__), :test)

if ENV['DEBUG'] == 'true'
  Mongo::Logger.logger.level = Logger::DEBUG
else
  Mongo::Logger.logger.level = Logger::INFO
end
# Mongo::Logger.logger.level = Logger::DEBUG

# Autoload every model for the test suite that sits in spec/app/models.
Dir[File.join(MODELS, '*.rb')].each do |file|
  name = File.basename(file, '.rb')
  autoload name.camelize.to_sym, name
end

# Require all support files.
Dir[File.join(SUPPORT, '*.rb')].each { |file| require file }

RSpec.configure do |config|
  config.before(:each) do
    Mongoid.purge!
    Mongoid::Geospatial::Config.reset!
  end
end

puts "Running with Mongoid v#{Mongoid::VERSION}"
