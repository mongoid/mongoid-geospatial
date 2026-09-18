# frozen_string_literal: true

require 'spec_helper'

describe Mongoid::Geospatial do
  it 'builds a $nearSphere selector in metres' do
    expect(described_class.near_query([-46.63, -23.55], 30)).to eq(
      '$geometry' => { 'type' => 'Point', 'coordinates' => [-46.63, -23.55] },
      '$maxDistance' => 30_000
    )
  end

  it 'mongoizes hashes for the selector' do
    coords = described_class.near_query({ lng: -46.63, lat: -23.55 }, 5)
                            .dig('$geometry', 'coordinates')
    expect(coords).to eq([-46.63, -23.55])
  end

  it 'refuses coordinates it cannot read' do
    expect { described_class.near_query('nowhere', 5) }.to raise_error(ArgumentError)
  end

  it 'wraps the GeoJSON metres form for a 2dsphere field' do
    expect(described_class.near_selector(:geom, [-46.63, -23.55], 30, sphere: true)).to eq(
      geom: { '$nearSphere' => described_class.near_query([-46.63, -23.55], 30) }
    )
  end

  it 'builds a legacy pair in radians for a 2d field' do
    expect(described_class.near_selector(:loc, [-46.63, -23.55], 30, sphere: false)).to eq(
      loc: { '$nearSphere' => [-46.63, -23.55],
             '$maxDistance' => 30 / Mongoid::Geospatial::EARTH_RADIUS_KM.to_f }
    )
  end

  it 'refuses a cap it cannot measure' do
    expect { described_class.near_query([1, 2], nil) }.to raise_error(ArgumentError)
    expect { described_class.near_query([1, 2], -5) }.to raise_error(ArgumentError)
  end
end

#
# `within` caps by km whatever the index is. A 2dsphere reads GeoJSON metres,
# a 2d reads a legacy pair in radians — and asking the wrong one of the two
# is `NoQueryExecutionPlans` from the server, not a wrong answer.
#
describe 'Mongoid::Geospatial#within' do
  # ~15km apart, and ~1150km out.
  let!(:here) { Place.create!(name: 'here', location: [10, 20]) }
  let!(:close) { Place.create!(name: 'close', location: [10.1, 20.1]) }
  let!(:far) { Place.create!(name: 'far', location: [21, 21]) }

  before { Place.create_indexes }

  after { Place.collection.indexes.drop_all }

  it 'caps in km on a field declared 2d' do
    expect(Place.within([10, 20], 5).to_a).to eq([here])
    expect(Place.within([10, 20], 20).to_a).to eq([here, close])
    expect(Place.within([10, 20], 2000).to_a).to eq([here, close, far])
  end

  it 'agrees with the distance Point#distance measures' do
    expect(here.location.distance(close.location)).to be_within(1).of(15)
    expect(Place.within(here.location, 16).to_a).to eq([here, close])
  end

  # `within(..).first` is the trap: Mongoid's #first sorts by _id when the
  # criteria carries no sort of its own, and that replaces the distance order
  # $near put there. `nearest` walks the criteria instead.
  describe '.nearest' do
    it 'answers the closest one, not the oldest one' do
      expect(Place.nearest([10.09, 20.09], 2000)).to eq(close)
      expect(Place.within([10.09, 20.09], 2000).first).to eq(here)
    end

    it 'answers nil when the cap excludes everything' do
      expect(Place.nearest([0, 0], 5)).to be_nil
    end
  end

  it 'caps in km on a field declared 2dsphere' do
    Alarm.create_indexes
    jfk = Alarm.create!(name: 'jfk', spot: [-73.77694444, 40.63861111])
    lax = Alarm.create!(name: 'lax', spot: [-118.40, 33.94])
    expect(Alarm.within(lax.spot, 10).to_a).to eq([lax])
    expect(Alarm.within(lax.spot, 5000).to_a).to eq([lax, jfk])
  ensure
    Alarm.collection.indexes.drop_all
  end
end

describe Mongoid::Geospatial::Geom do
  it 'declares geom as a 2dsphere Point' do
    field = GeomDesk.fields['geom']
    expect(field.type).to eq(Mongoid::Geospatial::Point)
    expect(field.options[:sphere]).to be true
    expect(GeomDesk.new(geom: [-46.63, -23.55])).to be_located
    expect(GeomDesk.new).not_to be_located
  end

  it 'names the pin when asked' do
    expect(GeomDesk.fields['pick_up'].options[:sphere]).to be true
  end

  # Two pins on one model (qir's Ride has pick_up and drop_up). Without
  # `field:` the second one is unaskable and the first one wins in silence.
  describe 'with two pins' do
    before { GeomDesk.create_indexes }

    after { GeomDesk.collection.indexes.drop_all }

    let!(:here) { GeomDesk.create!(geom: [10, 20], pick_up: [21, 21]) }
    let!(:there) { GeomDesk.create!(geom: [21, 21], pick_up: [10, 20]) }

    it 'reads the first spatial field by default' do
      expect(GeomDesk.within([10, 20], 5).to_a).to eq([here])
    end

    it 'reads the one it is handed' do
      expect(GeomDesk.within([10, 20], 5, field: :pick_up).to_a).to eq([there])
      expect(GeomDesk.nearest([10, 20], 5, field: :pick_up)).to eq(there)
      expect(GeomDesk.nearby([10, 20], field: :pick_up).to_a.first).to eq(there)
    end

    it 'says so when handed a field it has no pin for' do
      expect { GeomDesk.within([10, 20], 5, field: :nope) }.to raise_error(/nope/)
    end
  end
end
