# frozen_string_literal: true

require 'spec_helper'

describe 'RGeo Wrapper' do
  describe Mongoid::Geospatial::Point do
    it 'should not interfer with mongoid' do
      Bar.create!(name: "Moe's")
      expect(Bar.count).to eql(1)
    end

    it 'should not respond to distance before loading external' do
      bar = Bar.create!(location: [5, 5])
      expect(bar.location).not_to respond_to(:distance)
    end
  end

  describe Mongoid::Geospatial::Polygon do
    it 'should not interfer with mongoid' do
      Farm.create!(name: 'Springfield Nuclear Power Plant')
      expect(Farm.count).to eql(1)
    end

    it 'should respond to to_geo' do
      farm = Farm.create!(area: [[5, 5], [6, 5], [6, 6], [5, 6]])
      expect(farm.area).to respond_to(:to_geo)
    end
  end

  describe Mongoid::Geospatial::LineString do
    it 'should not interfer with mongoid' do
      River.create!(name: 'Mississippi')
      expect(River.count).to eql(1)
    end

    it 'should respond to to_geo before loading external' do
      river = River.create!(course: [[5, 5], [6, 5], [6, 6], [5, 6]])
      expect(river.course).to respond_to(:to_geo)
    end
  end

  describe 'queryable' do
    before do
      Mongoid::Geospatial.with_rgeo!
      Bar.create_indexes
      Farm.create_indexes
      River.create_indexes
    end

    describe '(de)mongoize' do
      describe Mongoid::Geospatial::Point do
        it 'should mongoize array' do
          geom = Bar.new(location: [10, -9]).location
          expect(geom.class).to eql(Mongoid::Geospatial::Point)
          expect(geom.x).to be_within(0.1).of(10)
        end

        it 'should wrap to georuby' do
          geom = Bar.new(location: [10, -9]).location
          expect(geom.to_geo.class)
            .to eql(GeoRuby::SimpleFeatures::Point)
          expect(geom.to_geo.y).to be_within(0.1).of(-9)
        end

        it 'should wrap to rgeo' do
          geom = Bar.new(location: [10, -9]).location
          expect(geom.to_rgeo.class)
            .to eql(RGeo::Geographic::SphericalPointImpl)
          expect(geom.to_rgeo.y).to be_within(0.1).of(-9)
        end

        it 'should mongoize hash' do
          geom = Bar.new(location: { x: 10, y: -9 }).location
          expect(geom.class).to eql(Mongoid::Geospatial::Point)
          expect(geom.to_rgeo.class)
            .to eql(RGeo::Geographic::SphericalPointImpl)
        end

        it 'should accept an RGeo object' do
          point = RGeo::Geographic.spherical_factory.point 1, 2
          bar = Bar.create!(location: point)
          expect(bar.location.x).to be_within(0.1).of(1)
          expect(bar.location.y).to be_within(0.1).of(2)
        end

        it 'should calculate 3d distances by default' do
          bar = Bar.create! location: [-73.77694444, 40.63861111]
          bar2 = Bar.create! location: [-118.40, 33.94] # ,:unit=>:mi
          expect(bar.location.rgeo_distance(bar2.location).to_i)
            .to be_within(1).of(3_978_262)
        end
      end

      describe Mongoid::Geospatial::Polygon do
        it 'should mongoize array' do
          geom = Farm.create!(area: [[5, 5], [6, 5], [6, 6], [5, 6]]).area
          expect(geom.class).to eql(Mongoid::Geospatial::Polygon)
          expect(geom.to_rgeo.class)
            .to eql(RGeo::Geographic::SphericalPolygonImpl)
          expect(geom.to_rgeo.to_s)
            .to eq 'POLYGON ((5.0 5.0, 6.0 5.0, 6.0 6.0, 5.0 6.0, 5.0 5.0))'
        end
      end

      describe Mongoid::Geospatial::LineString do
        it 'should mongoize array' do
          geom = River.create!(course: [[5, 5], [6, 5], [6, 6], [5, 6]]).course
          expect(geom.class).to eql(Mongoid::Geospatial::LineString)
          expect(geom.to_rgeo.class)
            .to eql(RGeo::Geographic::SphericalLineStringImpl)
          expect(geom.to_rgeo.to_s)
            .to eq 'LINESTRING (5.0 5.0, 6.0 5.0, 6.0 6.0, 5.0 6.0)'
        end
      end
    end
  end
end
