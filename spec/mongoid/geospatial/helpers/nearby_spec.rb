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
end
