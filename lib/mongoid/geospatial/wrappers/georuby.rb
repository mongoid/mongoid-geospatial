require 'geo_ruby'

module Mongoid
  #
  # Wrappers for GeoRuby
  # https://github.com/nofxx/georuby
  #
  module Geospatial
    # Wrapper to GeoRuby's Point
    Point.class_eval do
      # delegate :distance, to: :to_geo

      #
      # With GeoRuby support
      #
      # @return (GeoRuby::SimpleFeatures::Point)
      def to_geo
        return unless valid?

        GeoRuby::SimpleFeatures::Point.xy(x, y)
      end

      #
      # With GeoRuby support
      #
      # @return (Float)
      def geo_distance(other)
        to_geo.spherical_distance(other.to_geo)
      end
    end

    # Wrapper to GeoRuby's LineString
    LineString.class_eval do
      def to_geo
        GeoRuby::SimpleFeatures::LineString.from_coordinates(self)
      end
    end

    # Wrapper to GeoRuby's Polygon
    Polygon.class_eval do
      def to_geo
        GeoRuby::SimpleFeatures::Polygon.from_coordinates(self)
      end
    end
  end
end
