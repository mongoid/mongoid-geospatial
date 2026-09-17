# frozen_string_literal: true

# Spec model for Mongoid::Geospatial::Geom
class GeomDesk
  include Mongoid::Document
  include Mongoid::Geospatial::Geom

  geom :pick_up
end
