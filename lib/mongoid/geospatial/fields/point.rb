module Mongoid
  module Geospatial
    # Point
    #
    class Point
      include Enumerable
      attr_accessor :x, :y, :z

      def initialize(x, y, z = nil)
        @x = x
        @y = y
        @z = z
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

      def [](args)
        mongoize[args]
      end

      def each
        yield x
        yield y
      end

      #
      # Point representation as a Hash
      #
      # @return [Hash] with { xl => x, yl => y }
      #
      def to_hsh(xl = :x, yl = :y)
        { xl => x, yl => y }
      end
      alias to_hash to_hsh

      #
      # Helper for [self, radius]
      #
      # @return [Array] with [self, radius]
      #
      def radius(r = 1)
        [ mongoize, r ]
      end

      #
      # Radius Sphere
      #
      # Validates that #x & #y are `Numeric`
      #
      # @return [Array] with [self, radius / earth radius]
      #
      def radius_sphere(r = 1, unit = :km)
        radius r.to_f / Mongoid::Geospatial.earth_radius[unit]
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
      # Point definition as GeoJSON
      #
      # "x, y"
      #
      # @return [String] Point as comma separated String
      #
      def to_geo_json
        # Return a GeoJSON point hash that MongoDB can use
        { type: "Point", coordinates: [x, y] }
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
      # Distance calculation methods. Thinking about not using it
      # One needs to choose and external lib. GeoRuby or RGeo
      #
      # Return the distance between the 2D points (ie taking care
      # only of the x and y coordinates), assuming the points are
      # in projected coordinates. Euclidian distance in whatever
      # unit the x and y ordinates are.
      # def euclidian_distance(point)
      #   Math.sqrt((point.x - x)**2 + (point.y - y)**2)
      # end

      # # Spherical distance in meters, using 'Haversine' formula.
      # # with a radius of 6471000m
      # # Assumes x is the lon and y the lat, in degrees (Changed
      # in version 1.1).
      # # The user has to make sure using this distance makes sense
      # (ie she should be in latlon coordinates)
      # def spherical_distance(point,r=6370997.0)
      #   dlat = (point.lat - lat) * DEG2RAD / 2
      #   dlon = (point.lon - lon) * DEG2RAD / 2

      #   a = Math.sin(dlat)**2 + Math.cos(lat * DEG2RAD) *
      #         Math.cos(point.lat * DEG2RAD) * Math.sin(dlon)**2
      #   c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1-a))
      #   r * c
      # end

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

          str.split(/,|\s/).reject(&:empty?).map(&:to_f)
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
      end # << self
    end # Point
  end # Geospatial
end # Mongoid
