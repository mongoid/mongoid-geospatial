module Mongoid
  module Geospatial
    module Config
      module Point
        extend self

        attr_accessor :x
        attr_accessor :y

        def reset!
          self.x = Mongoid::Geospatial.lng_symbols
          self.y = Mongoid::Geospatial.lat_symbols
        end

        reset!
      end
    end
  end
end
