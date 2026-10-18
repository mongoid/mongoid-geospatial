# frozen_string_literal: true

require 'rgeo'
require 'mongoid/geospatial/ext/rgeo_spherical_point_impl'

Mongoid::Geospatial.factory ||= RGeo::Geographic.spherical_factory

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
        Mongoid::Geospatial.factory.point x, y
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
          Mongoid::Geospatial.factory.point(*pair)
        end
      end
    end

    # Wrapper to Rgeo's LineString
    LineString.class_eval do
      def to_rgeo
        Mongoid::Geospatial.factory.line_string(points)
      end
    end

    # Wrapper to Rgeo's Polygon
    Polygon.class_eval do
      def to_rgeo
        ring = Mongoid::Geospatial.factory.linear_ring(points)
        Mongoid::Geospatial.factory.polygon(ring)
      end
    end
  end
end
