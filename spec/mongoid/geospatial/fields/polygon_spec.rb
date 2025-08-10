# frozen_string_literal: true

require 'spec_helper'

describe Mongoid::Geospatial::Polygon do
  it 'should have correct indexes on farm' do
    Farm.create_indexes
    expect(Farm.collection.indexes.get(geom: '2dsphere')).not_to be_nil
  end

  describe '(de)mongoize' do
    it 'should support a field mapped as polygon' do
      farm = Farm.new(area: [[5, 5], [6, 5], [6, 6], [5, 6]])
      expect(farm.area).to be_a Mongoid::Geospatial::Polygon
      expect(farm.area).to eq([[5, 5], [6, 5], [6, 6], [5, 6]])
    end

    it 'should store as array on mongo' do
      Farm.create(area: [[5, 5], [6, 5], [6, 6], [5, 6]])
      expect(Farm.first.area).to eq([[5, 5], [6, 5], [6, 6], [5, 6]])
    end

    it 'should have a bounding box' do
      geom = Mongoid::Geospatial::Polygon.new [[1, 5], [6, 5], [6, 6], [5, 6]]
      expect(geom.bbox).to eq([[1, 5], [6, 6]])
    end

    it 'should have a center point' do
      geom = Mongoid::Geospatial::Polygon.new [[1, 1], [1, 1], [9, 9], [9, 9]]
      expect(geom.center).to eq([5.0, 5.0])
    end

    it 'should have a radius helper' do
      geom = Mongoid::Geospatial::Polygon.new [[1, 1], [1, 1], [9, 9], [9, 9]]
      expect(geom.radius(10)).to eq([[5.0, 5.0], 10])
    end

    it 'should have a radius sphere' do
      geom = Mongoid::Geospatial::Polygon.new [[1, 1], [1, 1], [9, 9], [9, 9]]
      expect(geom.radius_sphere(10)[1]).to be_within(0.001).of(0.001569)
    end

    it 'should handle BSON::Documents containing GeoJSON data' do
      coordinates = [[[1, 1], [1, 2], [1, 1]]]

      document = BSON::Document.new(type: 'Polygon', coordinates: coordinates)

      geom = Mongoid::Geospatial::Polygon.new(document)

      expect([*geom]).to eq(coordinates)
    end

    describe 'with rgeo' do
      before do
        Mongoid::Geospatial.with_rgeo!
        raise 'RGeo or RGeo::Feature::Polygon not loaded' unless defined?(RGeo::Feature::Polygon)
      end

      after do
        if Mongoid::Geospatial.const_defined?(:Wrappers) && Mongoid::Geospatial::Wrappers.const_defined?(:Rgeo) && Mongoid::Geospatial::Polygon.method_defined?(:to_rgeo)
          Mongoid::Geospatial::Polygon.send(:remove_method, :to_rgeo)
        end
        Mongoid::Geospatial.factory = nil
      end

      let(:farm_with_area) { Farm.new(area: [[5, 5], [6, 5], [6, 6], [5, 6], [5, 5]]) } # Closed polygon

      it 'should provide a #to_rgeo method returning an RGeo polygon object' do
        expect(farm_with_area.area).to be_a(Mongoid::Geospatial::Polygon)
        expect(farm_with_area.area).to respond_to(:to_rgeo)
        rgeo_polygon = farm_with_area.area.to_rgeo
        expect(rgeo_polygon).to be_a(RGeo::Feature::Polygon)
        # Basic check, RGeo polygon assertions can be more complex
        expect(rgeo_polygon.exterior_ring.points.count).to eq(5)
      end
    end
  end

  describe 'query' do
    context ':box, :polygon' do
      before do
        Farm.create_indexes
      end

      let(:ranch) do
        Farm.create!(name: 'Ranch',
                     area: [[1, 1], [3, 3], [3, 1], [1, 1]],
                     geom: [2, 2])
      end

      let(:farm) do
        Farm.create!(name: 'Farm',
                     area: [[47, 1], [48, 1.5], [49, 3], [49, 1], [47, 1]],
                     geom: [48, 1.28])
      end

      it 'returns the documents where geom is within the ranch.area polygon (defined as a box)' do
        # Changed from Farm.geo_spatial to Farm.where
        query = Farm.where(:geom.within_polygon => [ranch.area])
        expect(query.to_a).to eq([ranch])
      end

      it 'returns the documents where geom is within the farm.area polygon' do
        query = Farm.where(:geom.within_polygon => [farm.area])
        expect(query.to_a).to eq([farm])
      end

      it 'returns the documents within a circle (standard Mongoid query)' do
        pending 'Test for standard Mongoid/MongoDB $within behavior with $center operator (Moped legacy)'
        expect(Farm.where(:geom.within_circle =>
                           [ranch.geom, 0.4]).first).to eq(ranch)
      end

      it 'returns the documents within a spherical circle (standard Mongoid query)' do
        pending 'Test for standard Mongoid/MongoDB $within behavior with $centerSphere operator (Moped legacy)'
        expect(Farm.where(:geom.within_spherical_circle =>
                           [ranch.geom, 0.1]).first).to eq(ranch)
      end
    end
  end
end
