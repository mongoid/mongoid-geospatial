# frozen_string_literal: true

module Mongoid
  module Geospatial
    # Point
    #
    class Point # rubocop:disable Metrics/ClassLength
      include Enumerable

      attr_accessor :x, :y, :z
      alias lng x
      alias lon x
      alias lat y
      alias lng= x=
      alias lon= x=
      alias lat= y=

      def initialize(lon, lat, alt = nil)
        @x = lon
        @y = lat
        @z = alt
      end

      # Object -> Database
      # Let's store NilClass if we are invalid.
      #
      # @return (Array)
      def mongoize
        return nil unless x && y

        [x, y]
      end
      alias to_a mongoize
      alias to_xy mongoize
      alias to_lng_lat mongoize

      def [](args)
        raise ArgumentError, "Invalid point: #{inspect}" unless (pair = mongoize)

        pair[args]
      end

      def each
        yield x
        yield y
      end

      #
      # Helper for [self, radius]
      #
      # @return [Array] with [self, radius]
      #
      def radius(r = 1) # rubocop:disable Naming/MethodParameterName
        return nil unless (pair = mongoize)

        [pair, r]
      end

      #
      # Radius Sphere
      #
      # Validates that #x & #y are `Numeric`
      #
      # @return [Array] with [self, radius / earth radius]
      #
      def radius_sphere(r = 1, unit = :km) # rubocop:disable Naming/MethodParameterName
        radius r.to_f / Mongoid::Geospatial.earth_radius.fetch(unit)
      end

      #
      # Am I valid?
      #
      # Validates that #x & #y are `Numeric`
      #
      # @return [Boolean] if self #x && #y are valid
      #
      def valid?
        x && y && x.is_a?(Numeric) && y.is_a?(Numeric)
      end

      #
      # Point definition as string
      #
      # "x, y"
      #
      # @return [String] Point as comma separated String
      #
      def to_s
        "#{x}, #{y}"
      end

      #
      # Point representation as a Hash
      # Optional param: custom keys.
      #
      # @return [Hash] with { lng_key => x, lat_key => y }
      #
      def to_hsh(xkey = :x, ykey = :y)
        { xkey => x, ykey => y }
      end
      alias to_hash to_hsh

      #
      # Point representation more commonly used
      # Latitude, Longitude
      #
      # @return [Hash] with { latitude: y, longitude: x }
      def to_lat_lon
        { latitude: y, longitude: x }
      end

      #
      # Point definition as GeoJSON
      #
      # "x, y"
      #
      # @return [String] Point as comma separated String
      #
      def to_geo_json
        # Return a GeoJSON point hash that MongoDB can use
        { type: 'Point', coordinates: [x, y] }
      end

      #
      # Point inverse/reverse
      #
      # MongoDB: "x, y"
      # Reverse: "y, x"
      #
      # @return [Array] Point reversed: "y, x"
      #
      def reverse
        [y, x]
      end

      #
      # Crow-flies distance. Haversine, Mongo's earth radius (6371 km).
      # RGeo/GeoRuby still win for projections; this is ETA and "how far".
      #
      def distance(other, unit = :km) # rubocop:disable Metrics/AbcSize
        xy = other.is_a?(Point) ? [other.x, other.y] : self.class.mongoize(other)
        raise ArgumentError, "Invalid point: #{other.inspect}" unless xy&.size == 2

        dlat = (xy[1] - y) * RAD_PER_DEG
        dlon = (xy[0] - x) * RAD_PER_DEG
        a = (Math.sin(dlat / 2)**2) +
            (Math.cos(y * RAD_PER_DEG) * Math.cos(xy[1] * RAD_PER_DEG) *
             (Math.sin(dlon / 2)**2))
        c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a))
        Mongoid::Geospatial.earth_radius[unit] * c
      end

      class << self
        #
        # Database -> Object
        # Get it back
        def demongoize(obj)
          obj && new(*obj)
        end

        #
        # Object -> Database
        # Send it to MongoDB
        def mongoize(obj)
          case obj
          when Point  then obj.mongoize
          when String then from_string(obj)
          when Array  then from_array(obj)
          when Hash   then from_hash(obj)
          when NilClass then nil
          else
            return obj.to_xy if obj.respond_to?(:to_xy)

            raise 'Invalid Point'
          end
        end

        # Converts the object that was supplied to a criteria
        # into a database friendly form.
        def evolve(obj)
          case obj
          when Point then obj.mongoize
          else obj
          end
        end

        private

        #
        # Sanitize a `Point` from a `String`
        #
        # Makes life easier:
        # ""         ->    []
        # "1, 2"     ->    [1.0, 2.0]
        # "1.1 2.2"  ->    [1.1, 2.2]
        #
        # @return (Array)
        #
        def from_string(str)
          return nil if str.empty?

          from_array(str.split(/,|\s/).reject(&:empty?))
        end

        #
        # Sanitize a `Point` from an `Array`
        #
        # Also makes life easier:
        # []          ->   []
        # [1,2]       ->   [1.0, 2.0]
        #
        # @return (Array)
        #
        def from_array(array)
          return nil if array.empty?

          array.flatten[0..1].map(&:to_f)
        end

        #
        # Sanitize a `Point` from a `Hash`
        #
        # Uses Mongoid::Geospatial.lat_symbols & lng_symbols
        #
        # Also makes life easier:
        # {x: 1.0, y: 2.0}       ->  [1.0, 2.0]
        # {lat: 1.0, lon: 2.0}   ->  [1.0, 2.0]
        # {lat: 1.0, long: 2.0}  ->  [1.0, 2.0]
        #
        # Throws error if hash has less than 2 items.
        #
        # @return (Array)
        #
        def from_hash(hsh)
          coords = hsh[:coordinates] || hsh['coordinates']
          return from_array(coords) if coords

          raise 'Hash must have at least 2 items' if hsh.size < 2

          [from_hash_x(hsh), from_hash_y(hsh)]
        end

        def from_hash_y(hsh)
          v = (Mongoid::Geospatial::Config::Point.y & hsh.keys).first
          return hsh[v].to_f if !v.nil? && hsh[v]

          raise "Hash must contain #{Mongoid::Geospatial::Config::Point.y.inspect}"
        end

        def from_hash_x(hsh)
          v = (Mongoid::Geospatial::Config::Point.x & hsh.keys).first
          return hsh[v].to_f if !v.nil? && hsh[v]

          raise "Hash must contain #{Mongoid::Geospatial::Config::Point.x.inspect}"
        end
      end
    end
  end
end
