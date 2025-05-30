module Mongoid
  module Geospatial
    def self.from_array(ary)
      ary[0..1].map(&:to_f)
    end

    def self.from_hash(hsh)
      raise 'Hash must have at least 2 items' if hsh.size < 2

      [from_hash_x(hsh), from_hash_y(hsh)]
    end

    def self.from_hash_y(hsh)
      v = (Mongoid::Geospatial.lat_symbols & hsh.keys).first
      return hsh[v].to_f if !v.nil? && hsh[v]

      if Mongoid::Geospatial.lng_symbols.index(hsh.keys[1])
        raise "Hash cannot contain #{Mongoid::Geospatial.lng_symbols.inspect} "\
             "as second arg without #{Mongoid::Geospatial.lat_symbols.inspect}"
      end
      hsh.values[1].to_f
    end

    def self.from_hash_x(hsh)
      v = (Mongoid::Geospatial.lng_symbols & hsh.keys).first
      return hsh[v].to_f if !v.nil? && hsh[v]

      if Mongoid::Geospatial.lat_symbols.index(keys[0])
        raise "Hash cannot contain #{Mongoid::Geospatial.lat_symbols.inspect} "\
             "as first arg without #{Mongoid::Geospatial.lng_symbols.inspect}"
      end
      values[0].to_f
    end
  end
end
