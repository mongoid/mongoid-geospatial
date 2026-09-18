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

Mongo::Logger.logger.level = ENV['DEBUG'] == 'true' ? Logger::DEBUG : Logger::INFO

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

  # `with_rgeo!` / `with_georuby!` are a plain `require`: once any example
  # calls one, that wrapper is wired in for the rest of the run. File order
  # hid a spec that read #to_geo without asking for it. Random keeps it honest
  # — the seed is on the last line of every run if one ever goes red.
  config.order = :random
  Kernel.srand config.seed
end

puts "Running with Mongoid v#{Mongoid::VERSION}"
