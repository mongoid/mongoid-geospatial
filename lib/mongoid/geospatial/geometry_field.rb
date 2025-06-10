# frozen_string_literal: true

module Mongoid
  module Geospatial
    #
    #
    # Main Geometry Array
    #
    # All multi point classes inherit from this one:
    # LineString, Polygon, MultiPoint, MultiLineString, MultiPolygon
    #
    class GeometryField < Array
      #
      #
      # Determines the 2 points geometry bounding box.
      # Useful to find map boundaries, and fit to screen.
      # Returns [bottom left, top right]
      #
      # @return [Array] containing 2 points
      #
      def bounding_box
        max_x = -Float::MAX
        min_x = Float::MAX
        max_y = -Float::MAX
        min_y = Float::MAX
        each do |point|
          max_y = point[1] if point[1] > max_y
          min_y = point[1] if point[1] < min_y
          max_x = point[0] if point[0] > max_x
          min_x = point[0] if point[0] < min_x
        end
        [[min_x, min_y], [max_x, max_y]]
      end
      alias bbox bounding_box

      #
      # Determines the 5 points geometry bounding box.
      # Useful to use with Mongoid #within_geometry
      #
      # Returns a closed ring:
      # [bottom left, top left, top right, bottom right, bottom left]
      #
      # @return [Array] containing 5 points
      #
      def geom_box
        xl, yl = bounding_box
        [xl, [xl[0], yl[1]], yl, [yl[0], xl[1]], xl]
      end

      #
      # Determines the center point of a multi point geometry.
      # Geometry may be closed or not.
      #
      # @return [Array] containing 1 point [x,y]
      #
      def center_point
        min, max = *bbox
        [(min[0] + max[0]) / 2.0, (min[1] + max[1]) / 2.0]
      end
      alias center center_point

      #
      # Generates a radius from the point
      #
      # @param [Numeric] r radius
      # @return [Array]  [point, r] point and radius in mongoid format
      #
      def radius(r = 1) # rubocop:disable Naming/MethodParameterName
        [center, r]
      end

      #
      # Generates a spherical radius from the point
      #
      # point.radius(x) ->  [point, x / earth radius]
      #
      # @see Point#radius
      # @return [Array]
      #
      def radius_sphere(r = 1, unit = :km) # rubocop:disable Naming/MethodParameterName
        radius r.to_f / Mongoid::Geospatial.earth_radius[unit]
      end

      class << self
        #
        # Database -> Object
        #
        # @return [Object]
        def demongoize(obj)
          obj && new(obj)
        end
      end
    end
  end
end
