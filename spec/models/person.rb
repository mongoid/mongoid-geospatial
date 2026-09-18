# frozen_string_literal: true

# Somebody standing at a point. `Mongoid::Geospatial` with no field option:
# a Point that casts and reads back, with no index behind it — the specs use
# one as the "here" a query is asked FROM, never as the thing queried.
class Person
  include Mongoid::Document
  include Mongoid::Geospatial

  field :location, type: Point
end
