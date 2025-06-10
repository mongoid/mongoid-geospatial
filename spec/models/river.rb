# frozen_string_literal: true

# Sample spec class
class River
  include Mongoid::Document
  include Mongoid::Geospatial

  field :name,        type: String
  field :length,      type: Integer
  field :discharge,   type: Integer
  field :course,      type: LineString,   spatial: true
  # set return_array to true if you do not want a hash returned all the time
  field :source,      type: Point,        spatial: true
  field :mouth,       type: Point,        spatial: { lat: 'latitude', lng: 'longitude' }
  field :mouth_array, type: Array,        spatial: { return_array: true }

  # simplified spatial indexing
  # Note: Modern MongoDB versions support multiple 2d/2dsphere indexes per collection.
  spatial_index :source
  # alternatives
  # index [[ :spatial, Mongo::GEO2D ]], {min:-400, max:400}
  # index [[ :spatial, Mongo::GEO2D ]], {bit:32}
  # index [[ :spatial, Mongo::GEO2D ],:name]
end
