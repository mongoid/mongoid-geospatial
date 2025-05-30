# Sample spec class
class Bar
  include Mongoid::Document
  include Mongoid::Geospatial

  field :name,     type: String

  field :location, type: Point, spatial: true

  has_one :rating, as: :ratable

  spatial_index :location
  spatial_scope :location
end
