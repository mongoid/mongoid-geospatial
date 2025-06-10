# frozen_string_literal: true

require 'spec_helper'

describe Mongoid::Geospatial::Point do
  it 'should not interfer with mongoid' do
    Place.create!(name: "Moe's")
    expect(Place.count).to eql(1)
  end

  it 'should not respond to distance before loading external gem' do
    bar = Place.create!(location: [5, 5])
    expect(bar.location).not_to respond_to(:distance)
  end

  describe 'queryable' do
    before do
      Mongoid::Geospatial.with_georuby!
      Place.create_indexes
    end

    describe '(de)mongoize' do
      it 'should mongoize array' do
        geom = Place.new(location: [10, -9]).location
        expect(geom.class).to eql(Mongoid::Geospatial::Point)
        expect(geom.to_geo.class).to eql(GeoRuby::SimpleFeatures::Point)
        expect(geom.x).to be_within(0.1).of(10)
        expect(geom.to_geo.y).to be_within(0.1).of(-9)
      end

      it 'should mongoize hash' do
        geom = Place.new(location: { x: 10, y: -9 }).location
        expect(geom.class).to eql(Mongoid::Geospatial::Point)
        expect(geom.to_geo.class).to eql(GeoRuby::SimpleFeatures::Point)
      end

      it 'should accept a GeoRuby point' do
        point = GeoRuby::SimpleFeatures::Point.from_x_y 1, 2
        bar = Place.create!(location: point)
        expect(bar.location.x).to be_within(0.1).of(1)
        expect(bar.location.y).to be_within(0.1).of(2)
      end

      it 'should calculate 3d distances by default' do
        bar = Place.create! location: [-73.77694444, 40.63861111]
        bar2 = Place.create! location: [-118.40, 33.94] # ,:unit=>:mi, :spherical => true)
        expect(bar.location.geo_distance(bar2.location).to_i).to be_within(1).of(3_973_808)
      end

      describe 'simple features' do
        it 'should mongoize lines' do
          river = River.new(course: [[1, 2], [3, 4], [5, 6]])
          expect(river.course.to_geo)
            .to be_instance_of(GeoRuby::SimpleFeatures::LineString)
        end

        it 'should mongoize polygon' do
          farm = Farm.new(area: [[1, 2], [3, 4], [5, 6]])
          expect(farm.area.to_geo)
            .to be_instance_of(GeoRuby::SimpleFeatures::Polygon)
        end
      end
    end
  end
end
