# frozen_string_literal: true

module Mongoid
  module Geospatial
    # Circle
    #
    class Circle < GeometryField
      def center
        Point.new(*self[0])
      end
      alias point center

      def radius
        self[1]
      end
    end
  end
end
