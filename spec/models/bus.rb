# frozen_string_literal: true

# Sample spec class
# let's use to test as: :alias
class Bus
  include Mongoid::Document
  include Mongoid::Geospatial

  field :name
  field :plates,   type: String
  field :loc,      type: Point, delegate: true, as: :location

  spatial_index :location
  spatial_scope :location
end
