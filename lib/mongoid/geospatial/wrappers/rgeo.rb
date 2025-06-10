# frozen_string_literal: true

require 'rgeo'
require 'mongoid/geospatial/ext/rgeo_spherical_point_impl'

module Mongoid
  #
  # Wrappers for RGeo
  # https://github.com/rgeo/rgeo
  #
  module Geospatial
    # Wrapper to Rgeo's Point
    Point.class_eval do
      #
      # With RGeo support
      #
      # @return (RGeo::SphericalFactory::Point)
      def to_rgeo
        RGeo::Geographic.spherical_factory.point x, y
      end

      #
      # Distance with RGeo
      #
      # @return (Float)
      def rgeo_distance(other)
        to_rgeo.distance other.to_rgeo
      end
    end

    # Rgeo's GeometryField concept
    GeometryField.class_eval do
      def points
        map do |pair|
          RGeo::Geographic.spherical_factory.point(*pair)
        end
      end
    end

    # Wrapper to Rgeo's LineString
    LineString.class_eval do
      def to_rgeo
        RGeo::Geographic.spherical_factory.line_string(points)
      end
    end

    # Wrapper to Rgeo's Polygon
    Polygon.class_eval do
      def to_rgeo
        ring = RGeo::Geographic.spherical_factory.linear_ring(points)
        RGeo::Geographic.spherical_factory.polygon(ring)
      end
    end
  end
end
