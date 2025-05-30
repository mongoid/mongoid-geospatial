module Mongoid
  module Geospatial
    module Config
      autoload :Point, 'mongoid/geospatial/config/point'

      extend self

      def reset!
        Mongoid::Geospatial::Config::Point.reset!
      end

      def point
        Mongoid::Geospatial::Config::Point
      end

      reset!
    end

    class << self
      def configure
        block_given? ? yield(Config) : Config
      end

      def config
        Config
      end
    end
  end
end
