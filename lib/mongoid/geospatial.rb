require 'mongoid'
require 'active_support/concern' # Explicitly require for `extend ActiveSupport::Concern`
require 'mongoid/geospatial/helpers/spatial'
require 'mongoid/geospatial/helpers/sphere'
require 'mongoid/geospatial/helpers/delegate'

module Mongoid
  #
  # Main Geospatial module
  #
  # include Mongoid::Geospatial
  #
  module Geospatial
    autoload :GeometryField, 'mongoid/geospatial/geometry_field'

    autoload :Point,         'mongoid/geospatial/fields/point'
    autoload :LineString,    'mongoid/geospatial/fields/line_string'
    autoload :Polygon,       'mongoid/geospatial/fields/polygon'

    autoload :Box,           'mongoid/geospatial/fields/box'
    autoload :Circle,        'mongoid/geospatial/fields/circle'

    autoload :VERSION,       'mongoid/geospatial/version'

    extend ActiveSupport::Concern

    # Symbols accepted as 'longitude', 'x'...
    LNG_SYMBOLS = [:x, :lon, :long, :lng, :longitude,
                   'x', 'lon', 'long', 'lng', 'longitude'].freeze

    # Symbols accepted as 'latitude', 'y'...
    LAT_SYMBOLS = [:y, :lat, :latitude, 'y', 'lat', 'latitude'].freeze

    # For distance spherical calculations
    EARTH_RADIUS_KM = 6371 # taken directly from mongodb
    RAD_PER_DEG = Math::PI / 180

    # Earth radius in multiple units
    EARTH_RADIUS = {
      m:  EARTH_RADIUS_KM * 1000,
      km: EARTH_RADIUS_KM,
      mi: EARTH_RADIUS_KM * 0.621371192,
      ft: EARTH_RADIUS_KM * 5280 * 0.621371192,
      sm: EARTH_RADIUS_KM * 0.53995680345572 # sea mile
    }.freeze

    mattr_accessor :lng_symbols
    mattr_accessor :lat_symbols
    mattr_accessor :earth_radius
    mattr_accessor :factory

    @@lng_symbols  = LNG_SYMBOLS.dup
    @@lat_symbols  = LAT_SYMBOLS.dup
    @@earth_radius = EARTH_RADIUS.dup

    included do
      cattr_accessor :spatial_fields, :spatial_fields_indexed
      self.spatial_fields = []
      self.spatial_fields_indexed = []
    end

    def self.with_rgeo!
      require 'mongoid/geospatial/wrappers/rgeo'
    end

    def self.with_georuby!
      require 'mongoid/geospatial/wrappers/georuby'
    end

    # Methods applied to Document's class
    module ClassMethods
      #
      # Creates a 2d spatial index for the given field.
      #
      # @param name [String, Symbol] The name of the field to index.
      # @param options [Hash] Additional options for the index.
      #
      def spatial_index(name, options = {})
        spatial_fields_indexed << name
        index({ name => '2d' }, options)
      end

      #
      # Creates a 2dsphere index for the given field, suitable for spherical geometry calculations.
      #
      # @param name [String, Symbol] The name of the field to index.
      # @param options [Hash] Additional options for the index.
      #
      def sphere_index(name, options = {})
        spatial_fields_indexed << name
        index({ name => '2dsphere' }, options)
      end

      #
      # Defines a class method to find the closest document to a given point
      # using the specified spatial field via the `geoNear` command.
      #
      # @param field_name [String, Symbol] The name of the spatial field to query.
      # @param default_geo_near_options [Hash] Default options for the geoNear command
      #        (e.g., `{ spherical: true, max_distance: 1000 }`).
      #        The `key` option will be automatically set to `field_name`.
      #
      # Example:
      #   class Place
      #     include Mongoid::Document
      #     include Mongoid::Geospatial
      #     field :location, type: Array
      #     sphere_index :location # Assumes a 2dsphere index for spherical queries
      #     spatial_scope :location, spherical: true # Default to spherical for this scope
      #   end
      #
      #   Place.closest_to_location([lon, lat]) # Finds the single closest place
      #   Place.closest_to_location([lon, lat], max_distance: 500) # Override/add options
      #
      def spatial_scope(field_name, default_geo_near_options = {})
        method_name = :"closest_to_#{field_name}"
        key_name = field_name.to_s

        singleton_class.class_eval do
          define_method(method_name) do |coordinates, additional_options = {}|
            # `coordinates` should be [lon, lat] or a GeoJSON Point hash
            # e.g., { type: "Point", coordinates: [lon, lat] }
            geo_near_cmd_options = {
              near: coordinates,
              key: key_name
            }.merge(default_geo_near_options).merge(additional_options)

            queryable.geo_near(geo_near_cmd_options).first
          end
        end
      end

      #
      # Provides a convenient way to find documents near a given set of coordinates.
      # It automatically uses the first spatial field defined in the model and
      # determines whether to use a planar (.near) or spherical (.near_sphere)
      # query based on the field's definition options (`spatial: true` vs `sphere: true`).
      #
      # @param coordinates [Array, Mongoid::Geospatial::Point] The coordinates (e.g., [lon, lat])
      #   or a Point object to find documents near to.
      # @param _options [Hash] Optional hash for future extensions (currently unused).
      #
      # @return [Mongoid::Criteria] A criteria object for the query.
      #
      # Example:
      #   Bar.nearby([10, 20])
      #   Alarm.nearby(my_point_object)
      #
      def nearby(coordinates, _options = {})
        if self.spatial_fields.empty?
          raise "No spatial fields defined for #{self.name} to use with .nearby. " \
                "Mark a field with 'spatial: true' or 'sphere: true'."
        end

        field_name_sym = self.spatial_fields.first.to_sym
        field_definition = self.fields[field_name_sym.to_s]

        unless field_definition
          raise "Could not find field definition for spatial field: #{field_name_sym}"
        end

        query_operator = field_definition.options[:sphere] ? :near_sphere : :near

        criteria.where(field_name_sym.send(query_operator) => coordinates)
      end
    end
  end
end
