# frozen_string_literal: true

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
      m: EARTH_RADIUS_KM * 1000,
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
      def spherical_index(name, options = {})
        spatial_fields_indexed << name
        index({ name => '2dsphere' }, options)
      end

      #
      # # Queries
      #
      # MongoDB provides the following geospatial query operators.
      #
      # $geoIntersects
      # Selects geometries that intersect with a GeoJSON geometry.
      # The 2dsphere index supports $geoIntersects.
      #
      # $geoWithin
      # Selects geometries within a bounding GeoJSON geometry.
      # The 2dsphere and 2d indexes support $geoWithin.
      #
      # $near
      # Returns geospatial objects in proximity to a point.
      # Requires a geospatial index. The 2dsphere and 2d indexes support $near.
      #
      # $nearSphere
      # Returns geospatial objects in proximity to a point on a sphere.
      # Requires a geospatial index. The 2dsphere and 2d indexes support $nearSphere.
      #
      # # Aggregation
      #
      # MongoDB provides the following geospatial aggregation pipeline stage:
      #
      # $geoNear
      # Returns an ordered stream of documents based on the proximity to a geospatial point.
      # Incorporates the functionality of $match, $sort, and $limit for geospatial data.
      # The output documents include an additional distance field and can include a location identifier field.
      # $geoNear requires a geospatial index.
      #

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
      #     spherical_index :location # Assumes a 2dsphere index for spherical queries
      #     spatial_scope :location, spherical: true # Default to spherical for this scope
      #   end
      #
      #   Place.closest_to_location([lon, lat]) # Finds the single closest place
      #   Place.closest_to_location([lon, lat], max_distance: 500) # Override/add options
      #
      def spatial_scope(field_name, default_geo_near_options = {})
        method_name    = :"closest_to_#{field_name}"
        field_name_sym = field_name.to_sym
        # key_name       = field_name.to_s # Original geoNear used 'key' for field name

        singleton_class.class_eval do
          define_method(method_name) do |coordinates, additional_options = {}|
            # `coordinates` should be [lon, lat] or a GeoJSON Point hash
            # `self` here is the class (e.g., Bar)

            merged_options = default_geo_near_options.merge(additional_options)

            # Determine if spherical based on options or field definition
            is_spherical = if merged_options.key?(:spherical)
                             merged_options[:spherical]
                           else
                             # self.fields uses string keys for field names
                             field_def = fields[field_name.to_s]
                             field_def && field_def.options[:sphere]
                           end
            query_operator = is_spherical ? :near_sphere : :near

            # Prepare the value for the geospatial operator
            # Mongoid::Geospatial::Point.mongoize ensures coordinates are in [lng, lat] array format
            # from various input types (Point object, array, string, hash).
            mongoized_coords = Mongoid::Geospatial::Point.mongoize(coordinates)

            geo_query_value = if merged_options[:max_distance]
                                {
                                  # Using $geometry for clarity when $maxDistance is used,
                                  # which is standard for $near/$nearSphere operators.
                                  '$geometry' => { type: 'Point', coordinates: mongoized_coords },
                                  '$maxDistance' => merged_options[:max_distance].to_f
                                }
                              else
                                mongoized_coords # Simple array [lng, lat] for the operator
                              end

            # Start with a base criteria, applying an optional filter query
            current_criteria = merged_options[:query] ? where(merged_options[:query]) : all

            # Apply the geospatial query. $near and $nearSphere queries return sorted results.
            current_criteria.where(field_name_sym.send(query_operator) => geo_query_value)
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
        if spatial_fields.empty?
          raise "No spatial fields defined for #{name} to use with .nearby. " \
                "Mark a field with 'spatial: true' or 'sphere: true'."
        end

        field_name_sym = spatial_fields.first.to_sym
        field_definition = fields[field_name_sym.to_s]

        raise "Could not find field definition for spatial field: #{field_name_sym}" unless field_definition

        query_operator = field_definition.options[:sphere] ? :near_sphere : :near

        criteria.where(field_name_sym.send(query_operator) => coordinates)
      end

      # Performs a $geoNear aggregation pipeline stage to find documents near a point,
      # returning them sorted by distance and including the distance.
      #
      # This method is a wrapper around the MongoDB `$geoNear` aggregation stage,
      # which allows for more complex queries and options than the simple `near` or `near_sphere` methods.
      #
      # * But it's not chainable like a standard Mongoid query *
      #
      # @param field_name [String, Symbol] The name of the geospatial field to query.
      #   This field must be indexed with a geospatial index (2d or 2dsphere).
      # @param coordinates [Array, Hash, Mongoid::Geospatial::Point] The point to search near.
      #   Examples: `[lng, lat]`, `{ type: 'Point', coordinates: [lng, lat] }`, a `Mongoid::Geospatial::Point` object.
      # @param options [Hash] Options for the $geoNear stage.
      #   Key options include:
      #   - `:spherical` [Boolean] If true, calculates distances using spherical geometry. Defaults to `false`.
      #   - `:distanceField` [String] Name of the output field that will contain the distance. Defaults to `'distance'`.
      #   - `:maxDistance` [Numeric] The maximum distance from the center point that documents can be.
      #     For spherical queries, specify distance in meters. For 2d queries, in the same units as coordinates.
      #   - `:minDistance` [Numeric] The minimum distance. (MongoDB 2.6+)
      #   - `:query` [Hash] Limits the results to the documents that match the query.
      #   - `:limit` [Integer] The maximum number of documents to return (applied as a separate `$limit` pipeline stage).
      #   - `:distanceMultiplier` [Numeric] A factor to multiply all distances returned by the query.
      #   - `:includeLocs` [String] Specifies the name of the output field that identifies the location used to calculate the distance.
      #     This is useful when the queried field contains multiple locations (e.g., an array of points) or complex GeoJSON
      #     geometries (e.g., a Polygon), as it shows which specific point was used for the distance calculation.
      #     Example: `includeLocs: 'matchedPoint'` would add a `matchedPoint` field to each output document.
      #
      # @return [Array<Mongoid::Document>] An array of instantiated Mongoid documents.
      #   Each document will include its original fields plus any fields added by the `$geoNear` stage,
      #   such as the field specified by `:distanceField` (e.g., `document.distance`) and `:includeLocs`.
      #   These additional fields are accessible as dynamic attributes on the model instances.
      #
      # @raise [ArgumentError] If coordinates cannot be mongoized.
      #
      # Example:
      #   # Find places near [10, 20], using spherical calculations, up to 5km away
      #   Place.geo_near(:location, [10, 20],
      #                  spherical: true,
      #                  maxDistance: 5000, # 5 kilometers in meters
      #                  distanceField: 'dist.calculated',
      #                  query: { category: 'restaurant' },
      #                  limit: 10)
      #
      #   # Iterate over results
      #   Place.geo_near(:location, [10, 20], spherical: true).each do |place|
      #     puts "#{place.name} is #{place.distance} meters away." # Assumes distanceField is 'distance'
      #   end
      #
      def geo_near(field_name, coordinates, options = {})
        mongoized_coords = Mongoid::Geospatial::Point.mongoize(coordinates)

        raise ArgumentError, "Invalid coordinates provided: #{coordinates.inspect}" unless mongoized_coords

        # User-provided options. Work with a copy.
        user_options = options.dup
        limit_value = user_options.delete(:limit) # Handled by a separate pipeline stage

        # Core $geoNear parameters derived from method arguments, these are not overrideable by user_options.
        geo_near_core_params = {
          key: field_name.to_s,
          near: mongoized_coords
        }

        # Defaultable $geoNear parameters. User options will override these.
        geo_near_defaultable_params = {
          distanceField: 'distance',
          spherical: false # Default to planar (2d) calculations
        }

        # Merge user options over defaults, then ensure core parameters are set.
        geo_near_stage_options = geo_near_defaultable_params.merge(user_options).merge(geo_near_core_params)

        # Ensure :spherical is a strict boolean (true/false).
        # If user_options provided :spherical, it's already set. If not, the default is used.
        # This line ensures the final value is strictly true or false, not just truthy/falsy.
        geo_near_stage_options[:spherical] = !geo_near_stage_options[:spherical].nil?

        # Note on performance:
        # $geoNear is an aggregation pipeline stage. For simple proximity queries,
        # it might exhibit slightly higher "real" time (wall-clock time) in benchmarks
        # compared to direct query operators like $near or $nearSphere. This is often
        # due to the inherent overhead of the aggregation framework versus a direct query.
        # However, $geoNear offers more capabilities, such as returning the distance
        # (distanceField), distanceMultiplier, includeLocs, and integrating with other
        # aggregation stages, which are not available with $near/$nearSphere.
        pipeline = [{ '$geoNear' => geo_near_stage_options }]

        # Add $limit stage if limit_value was provided
        pipeline << { '$limit' => limit_value.to_i } if limit_value

        # Execute the aggregation pipeline
        collection.aggregate(pipeline)

        # Don't instantiate results here.
        # aggregated_results = collection.aggregate(pipeline)
        # Map the raw Hash results from aggregation to Mongoid model instances.
        # Mongoid's #instantiate method correctly handles creating model objects
        # and assigning attributes, including dynamic ones like the distanceField.
        # aggregated_results.map { |attrs| instantiate(attrs) }
      end
    end
  end
end
require 'mongoid/geospatial/config'
