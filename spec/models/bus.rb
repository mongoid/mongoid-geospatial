# frozen_string_literal: true

# Sample spec class
class Bus
  include Mongoid::Document
  include Mongoid::Geospatial

  field :name
  field :plates,   type: String
  field :location, type: Point, delegate: true

  spatial_index :location
  spatial_scope :location
end
