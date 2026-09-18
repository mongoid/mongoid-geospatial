# frozen_string_literal: true

require 'spec_helper'

describe Mongoid::Geospatial::Config do
  context 'point' do
    it 'uses LonLat by default' do
      expect(Mongoid::Geospatial.config.point.x).to eq Mongoid::Geospatial.lng_symbols
      expect(Mongoid::Geospatial.config.point.y).to eq Mongoid::Geospatial.lat_symbols
    end

    # It used to hand out the very same Array, so `config.point.x << :foo`
    # edited Mongoid::Geospatial.lng_symbols behind your back.
    it 'hands out its own copy, not the module list' do
      expect(Mongoid::Geospatial.config.point.x).not_to be Mongoid::Geospatial.lng_symbols
      Mongoid::Geospatial.config.point.x << :nope
      expect(Mongoid::Geospatial.lng_symbols).not_to include(:nope)
    end
    context 'configured as latlon' do
      before do
        Mongoid::Geospatial.configure do |config|
          config.point.x = Mongoid::Geospatial.lat_symbols
          config.point.y = Mongoid::Geospatial.lng_symbols
        end
      end
      it 'uses latlon' do
        expect(Mongoid::Geospatial.config.point.x).to eq Mongoid::Geospatial.lat_symbols
        expect(Mongoid::Geospatial.config.point.y).to eq Mongoid::Geospatial.lng_symbols
      end
    end
  end
end
