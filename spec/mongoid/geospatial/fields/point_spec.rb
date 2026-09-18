# frozen_string_literal: true

require 'spec_helper'

describe Mongoid::Geospatial::Point do
  describe "Moe's Bar" do
    let(:bar) { Bar.create!(name: "Moe's") }

    it 'does not interfere with mongoid' do
      expect(bar.class.count).to eql(1)
    end

    it 'does not fail if point is nil' do
      expect(bar.location).to be_nil
    end

    it 'sets point methodically' do
      bar.location = Mongoid::Geospatial::Point.new(8, 9)
      expect(bar.save).to be_truthy
      expect(Bar.first.location.x).to eq(8)
      expect(Bar.first.location.y).to eq(9)
    end

    it 'sets point with comma separated text' do
      bar.location = '2.99,3.99'
      expect(bar.location.mongoize).to eq([2.99, 3.99])
    end

    it 'sets point with space separated text' do
      bar.location = '2.99 3.99'
      expect(bar.location.mongoize).to eq([2.99, 3.99])
    end

    it 'sets point with space comma separated text' do
      bar.location = '2.99 ,  3.99'
      expect(bar.location.mongoize).to eq([2.99, 3.99])
    end

    it 'sets point from hash' do
      bar.location = { latitude: 2.99, longitude: 3.99 }
      expect(bar.location.mongoize).to eq([3.99, 2.99])
    end

    context 'configured as latlon' do
      before do
        Mongoid::Geospatial.configure do |config|
          config.point.x = Mongoid::Geospatial.lat_symbols
          config.point.y = Mongoid::Geospatial.lng_symbols
        end
      end
      it 'reads that same hash the other way round' do
        bar.location = { latitude: 2.99, longitude: 3.99 }
        expect(bar.location.mongoize).to eq([2.99, 3.99])
      end
    end
  end

  it 'has a to_s method that correctly formats points' do
    bar1 = Bar.create!(name: "Moe's", location: [1, 2])
    expect(bar1.location.to_s).to eq('1.0, 2.0')

    bar2 = Bar.create!(name: "Moe's", location: [1.0009, 21.009])
    expect(bar2.location.to_s).to eq('1.0009, 21.009')
  end

  it 'has a to_lat_lon method that correctly formats points' do
    bar = Bar.create!(name: "Moe's", location: [1, 2])
    expect(bar.location.to_lat_lon).to eq({ latitude: 2.0, longitude: 1.0 })
  end

  it 'has a customizable to_hsh method that correctly formats points' do
    bar = Bar.create!(name: "Moe's", location: [1, 2])
    expect(bar.location.to_hsh(:lon, :lat)).to eq({ lon: 1.0, lat: 2.0 })
  end

  it 'has a to_geo_json method' do
    bar = Bar.create!(name: "Moe's", location: [1.0009, 21.009])
    expect(bar.location.to_geo_json).to eq({
                                             type: 'Point', coordinates: [1.0009, 21.009]
                                           })
  end

  it 'has a to_json method' do
    bar = Bar.create!(name: "Moe's", location: [1.0009, 21.009])
    expect(bar.location.to_json).to eq('[1.0009,21.009]')
  end

  it 'has #reverse to get lat, lon' do
    bar = Bar.create!(name: "Moe's", location: [1, 2])
    expect(bar.location.reverse).to eq([2, 1])
  end

  it 'sets point to nil' do
    bar = Bar.create!(name: "Moe's", location: [1, 1])
    bar.location = nil
    expect(bar.location).to be_nil
    expect(bar.save).to be_truthy
    expect(Bar.where(location: nil).first).to eq(bar)
  end

  it 'updates point x' do
    bar = Bar.create!(name: "Moe's", location: [1, 1])
    bar.location = [2, 3]
    expect(bar.save).to be_truthy
    expect(Bar.first.location.to_a).to eq([2, 3])
  end

  it 'sets point empty string to nil' do
    bar = Bar.create!(name: "Moe's", location: [1, 1])
    bar.location = ''
    expect(bar.location).to be_nil
    expect(bar.save).to be_truthy
    expect(Bar.where(location: nil).first).to eq(bar)
  end

  it 'sets point empty array to nil' do
    bar = Bar.create!(name: "Moe's", location: [1, 1])
    bar.location = []
    expect(bar.location).to be_nil
    expect(bar.save).to be_truthy
    expect(Bar.where(location: nil).first).to eq(bar)
  end

  describe 'methods' do
    let(:bar) { Bar.create!(location: [3, 2]) }

    it 'has a .to_a' do
      expect(bar.location.to_a[0..1]).to eq([3.0, 2.0])
    end

    it 'has an array [] accessor' do
      expect(bar.location[0]).to eq(3.0)
    end

    it 'has an ActiveModel symbol accessor' do
      expect(bar[:location].to_a).to eq([3, 2])
    end

    it 'has a radius helper' do
      expect(bar.location.radius).to eql([[3.0, 2.0], 1])
    end

    it 'has a radius sphere helper' do
      expect(bar.location.radius_sphere[1])
        .to be_within(0.0001).of(0.00015)
    end

    it 'has a radius sphere helper in meters' do
      expect(bar.location.radius_sphere(1000, :m)[1])
        .to be_within(0.0001).of(0.00015)
    end

    it 'has a radius sphere helper in miles' do
      expect(bar.location.radius_sphere(1, :mi)[1])
        .to be_within(0.0001).of(0.00025)
    end

    it 'answers lat/lng as y/x' do
      expect([bar.location.lng, bar.location.lat]).to eq([3.0, 2.0])
    end

    it 'walks crow-flies km (JFK–LAX)' do
      jfk = described_class.new(-73.7781, 40.6413)
      lax = described_class.new(-118.4085, 33.9416)
      expect(jfk.distance(lax)).to be_within(30).of(3974)
      expect(jfk.distance(lax, :mi)).to be_within(20).of(2470)
      expect(jfk.distance([-118.4085, 33.9416])).to be_within(30).of(3974)
    end
  end

  describe 'queryable' do
    before do
      Bar.create_indexes
    end

    describe ':near :near_sphere' do
      # [lng, lat], the order Mongo stores. Jim is in Barcelona, and the three
      # are 830 / 1350 / 1500 km out from him, in that order.
      let!(:berlin) do
        Bar.create(name: :berlin, location: [13.40, 52.52])
      end

      let!(:prague) do
        Bar.create(name: :prague, location: [14.42, 50.08])
      end

      let!(:paris) do
        Bar.create(name: :paris, location: [2.35, 48.86])
      end

      let!(:jim) do
        Person.new(location: [2.17, 41.39])
      end

      it 'sorts closest to furthest through the spatial_scope' do
        expect(Bar.closest_to_location(jim.location).to_a)
          .to eq([paris, prague, berlin])
      end

      it 'sorts closest to furthest through the symbol key' do
        expect(Bar.where(:location.near => jim.location).to_a)
          .to eq([paris, prague, berlin])
      end

      it 'sorts closest to furthest through .near' do
        expect(Bar.near(location: jim.location))
          .to eq([paris, prague, berlin])
      end

      it 'sorts closest to furthest through .near_sphere' do
        expect(Bar.near_sphere(location: jim.location))
          .to eq([paris, prague, berlin])
      end

      it 'sorts closest to furthest through the near_sphere symbol key' do
        expect(Bar.where(:location.near_sphere => jim.location))
          .to eq([paris, prague, berlin])
      end

      it 'returns the documents sorted closest to furthest with max' do
        expect(Bar.near(location: jim.location).max_distance(location: 10).to_a)
          .to eq([paris]) # , prague, berlin ]
      end
    end

    describe ':within_circle :within_spherical_circle' do
      let!(:mile1) do
        Bar.create(name: 'mile1', location: [-73.997345, 40.759382])
      end

      let!(:mile3) do
        Bar.create(name: 'mile3', location: [-73.927088, 40.752151])
      end

      let!(:mile7) do
        Bar.create(name: 'mile7', location: [-74.0954913, 40.7161472])
      end

      let!(:mile9) do
        Bar.create(name: 'mile9', location: [-74.0604951, 40.9178011])
      end

      let!(:elvis) do
        Person.new(location: [-73.98, 40.75])
      end

      # mile1 is 1.8km out, mile3 4.46km, mile7 10.43km, mile9 19.85km.
      it 'returns the documents within a spherical circle, radius in km' do
        expect(Bar.where(:location.within_spherical_circle =>
                         elvis.location.radius_sphere(5, :km)).to_a)
          .to match_array([mile1, mile3])
      end

      it 'draws the circle Point#distance measures' do
        expect(Bar.where(:location.within_spherical_circle =>
                         elvis.location.radius_sphere(2, :km)).to_a).to eq([mile1])
        expect(elvis.location.distance(mile1.location)).to be < 2
        expect(elvis.location.distance(mile3.location)).to be > 2
      end

      # `$center` reads degrees, not km — a flat circle on a legacy pair.
      it 'returns the documents within a circle' do
        expect(Bar.where(:location.within_circle => elvis.location.radius(0.05)).to_a)
          .to eq([mile1])
        expect(Bar.where(:location.within_circle => elvis.location.radius(0.2)).to_a)
          .to match_array([mile1, mile3, mile7, mile9])
      end

      it 'returns the documents within a box' do
        poly = Mongoid::Geospatial::LineString.new(
          [elvis.location.map { |c| c + 1 },
           elvis.location.map { |c| c - 1 }]
        )
        expect(Bar.where(:location.within_polygon => [poly.geom_box]).to_a)
          .to include(mile3)
      end
    end
  end

  describe '(de)mongoize' do
    it 'mongoizes array' do
      bar = Bar.new(location: [10, -9])
      expect(bar.location.class).to eql(Mongoid::Geospatial::Point)
      expect(bar.location.x).to be_within(0.1).of(10)
      expect(bar.location.y).to be_within(0.1).of(-9)
    end

    it 'mongoizes hash' do
      geom = Bar.new(location: { x: 10, y: -9 }).location
      expect(geom.class).to eql(Mongoid::Geospatial::Point)
      expect(geom.x).to be_within(0.1).of(10)
      expect(geom.y).to be_within(0.1).of(-9)
    end

    it 'mongoizes hash with symbols in any order' do
      geom = Bar.new(location: { y: -9, x: 10 }).location
      expect(geom.class).to eql(Mongoid::Geospatial::Point)
      expect(geom.x).to be_within(0.1).of(10)
      expect(geom.y).to be_within(0.1).of(-9)
    end

    it 'mongoizes hash with string keys in any order' do
      geom = Bar.new(location: { 'y' => -9, 'x' => 10 }).location
      expect(geom.class).to eql(Mongoid::Geospatial::Point)
      expect(geom.x).to be_within(0.1).of(10)
      expect(geom.y).to be_within(0.1).of(-9)
    end

    # It is the shape #to_geo_json writes, the shape Mongo stores a 2dsphere
    # geometry in, and the shape .geo_near documents. Read it back.
    it 'reads the GeoJSON it writes, either key flavour' do
      point = described_class.new(1.0009, 21.009)
      expect(described_class.mongoize(point.to_geo_json)).to eq([1.0009, 21.009])
      expect(described_class.mongoize('type' => 'Point', 'coordinates' => [10, -9]))
        .to eq([10.0, -9.0])
    end

    it 'keeps two coordinates from a string, like it does from an array' do
      expect(described_class.mongoize('1 2 3')).to eq([1.0, 2.0])
      expect(described_class.mongoize([1, 2, 3])).to eq([1.0, 2.0])
    end

    it 'says which point it could not read' do
      expect { described_class.new(1, 2).distance('7') }.to raise_error(ArgumentError)
      expect { described_class.new(1, nil)[0] }.to raise_error(ArgumentError)
    end

    # should raise
    # geom.to_geo

    describe 'with rgeo' do
      before do
        # Ensure RGeo is loaded for this context
        Mongoid::Geospatial.with_rgeo!
        # Ensure RGeo::Feature::Point is available for the test
        raise 'RGeo or RGeo::Feature::Point not loaded' unless defined?(RGeo::Feature::Point)
      end

      # No teardown: `with_rgeo!` is a `require`, so the first example that
      # calls it wires #to_rgeo in for the whole run. There is nothing to undo.

      describe 'instantiated' do
        let(:bar) { Bar.new(name: 'Vitinho', location: [10, 10]) }

        it 'provides a #to_rgeo method returning an RGeo point object' do
          expect(bar.location).to be_a(Mongoid::Geospatial::Point)
          expect(bar.location).to respond_to(:to_rgeo)
          rgeo_point = bar.location.to_rgeo
          expect(rgeo_point).to be_a(RGeo::Feature::Point)
          expect(rgeo_point.x).to be_within(0.00001).of(10.0)
          expect(rgeo_point.y).to be_within(0.00001).of(10.0)
        end
      end
    end
  end
end
