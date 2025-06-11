# frozen_string_literal: true

module Mongoid
  module Geospatial
    module Config
      module Point
        extend self

        attr_accessor :x, :y

        def reset!
          # Now self.x and self.y refer to the public module accessors
          self.x = Mongoid::Geospatial.lng_symbols
          self.y = Mongoid::Geospatial.lat_symbols
        end

        # Initialize the configuration
        reset!
      end
    end
  end
end
