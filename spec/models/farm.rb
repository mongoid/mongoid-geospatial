# frozen_string_literal: true

# Sample spec class
class Farm
  include Mongoid::Document
  include Mongoid::Geospatial

  field :name,         type: String
  field :geom,         type: Point,    sphere: true
  field :area,         type: Polygon,  spatial: true
  field :m2,           type: Integer

  # sphere: true on :geom already creates a 2dsphere index.
  # spatial: true on :area already creates a 2d index.
  # These explicit calls are redundant unless specific options were needed.
  # spatial_index :geom
  # spatial_index :area
end
