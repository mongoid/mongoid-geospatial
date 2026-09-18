# frozen_string_literal: true

require 'mongoid'
require 'active_support/concern' # Explicitly require for `extend ActiveSupport::Concern`
require 'mongoid/geospatial/helpers/spatial'
require 'mongoid/geospatial/helpers/sphere'
require 'mongoid/geospatial/helpers/delegate'
require 'mongoid/geospatial/helpers/geom'
require 'mongoid/geospatial/keys'

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

    #
    # A [lng, lat] pair, or nothing. `Point.mongoize` is lenient — it reads
    # "nowhere" as [0.0] — and a half pair is a query Mongo cannot answer.
    #
    def self.mongoize_point!(geom)
      coords = Point.mongoize(geom)
      unless coords.is_a?(Array) && coords.size == 2 && coords.all?(Numeric)
        raise ArgumentError, "Invalid coordinates: #{geom.inspect}"
      end

      coords
    end

    #
    # A cap Mongo can measure: a positive number of kilometres.
    #
    def self.km!(km) # rubocop:disable Naming/MethodParameterName
      raise ArgumentError, "Invalid km: #{km.inspect}" unless km.is_a?(Numeric) && km.positive?

      km
    end

    #
    # `$nearSphere` value with a km cap, GeoJSON. Metres on the wire.
    # This is the 2dsphere shape — see #near_selector for the other one.
    #
    def self.near_query(geom, km) # rubocop:disable Naming/MethodParameterName
      { '$geometry' => { 'type' => 'Point', 'coordinates' => mongoize_point!(geom) },
        '$maxDistance' => km!(km) * 1_000 }
    end

    #
    # The whole `{ field => ... }` selector for "within +km+", for either index.
    #
    # `$nearSphere` speaks two dialects and the index picks which:
    #
    #   2dsphere   { loc: { $nearSphere: { $geometry: {...}, $maxDistance: <m> } } }
    #   2d         { loc: { $nearSphere: [x, y],             $maxDistance: <rad> } }
    #
    # Hand the wrong one over and the server answers `NoQueryExecutionPlans`,
    # not a wrong count — so ask the field which it is before building.
    #
    def self.near_selector(field, geom, km, sphere: true) # rubocop:disable Naming/MethodParameterName
      return { field => { '$nearSphere' => near_query(geom, km) } } if sphere

      { field => { '$nearSphere' => mongoize_point!(geom),
                   '$maxDistance' => km!(km) / EARTH_RADIUS_KM.to_f } }
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
        remember_indexed(name)
        index({ name => '2d' }, options)
      end

      #
      # Creates a 2dsphere index for the given field, suitable for spherical geometry calculations.
      #
      # @param name [String, Symbol] The name of the field to index.
      # @param options [Hash] Additional options for the index.
      #
      def spherical_index(name, options = {})
        remember_indexed(name)
        index({ name => '2dsphere' }, options)
      end
      alias sphere_index spherical_index

      #
      # One field, one entry, always a Symbol — a field may carry both a 2d
      # and a 2dsphere index, and `spatial: true` calls this on its way in too.
      #
      def remember_indexed(name)
        sym = name.to_sym
        spatial_fields_indexed << sym unless spatial_fields_indexed.include?(sym)
      end

      #
      # A Point on a 2dsphere index. Default name is `geom`.
      #
      def geom(name = :geom)
        field name, type: Point, sphere: true
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
      # @param km [Numeric, nil] Optional cap in kilometres.
      #
      # @return [Mongoid::Criteria] A criteria object for the query.
      #
      # Example:
      #   Bar.nearby([10, 20])
      #   Alarm.nearby(my_point_object, km: 30)
      #
      def nearby(coordinates, km: nil, field: nil) # rubocop:disable Naming/MethodParameterName
        pin, sphere = spatial_field(field)
        return criteria.where(Mongoid::Geospatial.near_selector(pin, coordinates, km, sphere: sphere)) if km

        criteria.where(pin.send(sphere ? :near_sphere : :near) => coordinates)
      end

      #
      # The pin `.nearby`, `.within` and `.nearest` read, and whether it is on
      # a sphere. Handed nothing, the first spatial field — a model with two
      # pins (`geom :pick_up`, `geom :drop_up`) has to name the one it means.
      #
      # @return [Array] [field name as a Symbol, sphere?]
      #
      def spatial_field(field = nil)
        sym = (field || spatial_fields.first)&.to_sym
        unless sym && spatial_fields.include?(sym)
          raise ArgumentError, "#{name} has no spatial field #{sym.inspect} — it has #{spatial_fields.inspect}. " \
                               "Mark one with 'spatial: true' or 'sphere: true'."
        end

        [sym, fields.fetch(sym.to_s).options[:sphere] ? true : false]
      end

      #
      # Documents within +km+ of +geom+, nearest first. Spherical either way:
      # the field's index decides the dialect, see .near_selector.
      #
      def within(geom, km, field: nil) # rubocop:disable Naming/MethodParameterName
        nearby(geom, km: Mongoid::Geospatial.km!(km), field: field)
      end

      #
      # The single closest document within +km+, or nil.
      #
      #   `within(geom, km).first`   NOT the nearest one
      #   `nearest(geom, km)`        the nearest one
      #
      # Mongoid's #first and #last sort by `_id` when the criteria carries no
      # sort of its own (contextual/mongo.rb, `view.sort || { _id: 1 }`), and
      # that _id sort replaces the distance order `$near` put there. It reads
      # as working every time the closest document happens to be the oldest.
      #
      def nearest(geom, km, field: nil) # rubocop:disable Naming/MethodParameterName
        within(geom, km, field: field).limit(1).to_a.first
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
      #   - `:limit` [Integer] The maximum number of documents to return
      #     (applied as a separate `$limit` pipeline stage).
      #   - `:distanceMultiplier` [Numeric] A factor to multiply all distances by.
      #   - `:includeLocs` [String] Output field naming WHICH location the distance
      #     was measured to — the one that matters when the queried field holds
      #     several points, or a Polygon. `includeLocs: 'matchedPoint'` adds a
      #     `matchedPoint` field to each output document.
      #
      # @return [Mongo::Collection::View::Aggregation] The raw pipeline result — it
      #   yields `BSON::Document` hashes, NOT model instances, so read a field with
      #   `doc['name']` and the distance with `doc['distance']` (or whatever
      #   `:distanceField` was set to). Nothing is instantiated: `$geoNear` adds fields
      #   a document does not have, and a Point field comes back as a raw pair.
      #   Need models? `.map { |attrs| Model.instantiate(attrs) }` at the call site.
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
      #   # Iterate over results — hashes, not documents
      #   Place.geo_near(:location, [10, 20], spherical: true).each do |doc|
      #     puts "#{doc['name']} is #{doc['distance']} meters away."
      #   end
      #
      def geo_near(field_name, coordinates, options = {})
        mongoized_coords = Mongoid::Geospatial.mongoize_point!(coordinates)

        # User-provided options. Work with a copy.
        user_options = options.dup
        limit_value = user_options.delete(:limit) # Handled by a separate pipeline stage

        # `km:` is metres on the wire, and metres only holds for a GeoJSON
        # `near` on a sphere. A legacy pair would read `maxDistance` in radians.
        if (km = user_options.delete(:km))
          user_options[:maxDistance] = km.to_f * 1_000
          user_options[:spherical] = true
          mongoized_coords = { 'type' => 'Point', 'coordinates' => mongoized_coords }
        end

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

        # $geoNear wants a strict boolean, and honours the caller's choice.
        geo_near_stage_options[:spherical] = geo_near_stage_options[:spherical] ? true : false

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

        collection.aggregate(pipeline)
      end
    end
  end
end
require 'mongoid/geospatial/config'
