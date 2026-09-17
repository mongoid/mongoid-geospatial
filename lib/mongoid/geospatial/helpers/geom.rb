# frozen_string_literal: true

module Mongoid
  module Geospatial
    #
    # The pin, named `geom`, on a 2dsphere index.
    #
    module Geom
      extend ActiveSupport::Concern

      included do
        include Mongoid::Geospatial

        geom
      end

      def located?
        geom.present?
      end
    end
  end
end
