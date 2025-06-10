# frozen_string_literal: true

module RGeo
  module Geographic
    # RGeo Point
    class SphericalPointImpl
      def to_xy
        [x, y]
      end

      def to_a
        [x, y, z]
      end

      def [](index)
        to_a[index]
      end
    end
  end
end
