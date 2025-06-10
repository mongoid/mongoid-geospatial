# frozen_string_literal: true

# Sample spec class
class Alarm
  include Mongoid::Document
  include Mongoid::Geospatial

  field :name
  field :radius,  type: Circle
  field :area,    type: Box
  field :spot,    type: Point, sphere: true

  spatial_scope :spot
end
