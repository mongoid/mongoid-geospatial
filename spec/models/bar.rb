# frozen_string_literal: true

# Sample spec class
class Bar
  include Mongoid::Document
  include Mongoid::Geospatial

  field :name,     type: String

  # `spatial: true` builds the 2d index; `spherical_index` below adds a 2dsphere
  # on the SAME field, on purpose — one model covering both, which is legal in
  # Mongo. It is also what hid the 7.2 `within` blocker: a 2d-only field has no
  # 2dsphere to answer $nearSphere with, and Bar always had one. Place is the
  # 2d-only model; keep it that way.
  field :location, type: Point, spatial: true

  has_one :rating, as: :ratable

  spherical_index :location
  spatial_scope :location
end
