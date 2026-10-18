# frozen_string_literal: true

require 'spec_helper'

describe Mongoid::Geospatial::Point do
  it 'demongoizes GeoJSON with either key flavour and BSON documents' do
    [
      { type: 'Point', coordinates: [10, -9] },
      { 'type' => 'Point', 'coordinates' => [10, -9] },
      BSON::Document.new(type: 'Point', coordinates: [10, -9])
    ].each do |document|
      expect(described_class.demongoize(document).to_a).to eq([10, -9])
    end
  end

  it 'persists GeoJSON point input on a spherical field and finds it again' do
    Alarm.create_indexes
    alarm = Alarm.create!(spot: described_class.new(10, -9).to_geo_json)

    expect(alarm.reload.spot.to_a).to eq([10, -9])
    expect(Alarm.within([10, -9], 1).to_a).to eq([alarm])
  end

  it 'loads and queries a GeoJSON point written directly to MongoDB' do
    Alarm.create_indexes
    alarm = Alarm.create!(name: 'GeoJSON')
    Alarm.collection.find(_id: alarm.id).update_one(
      '$set' => { spot: { type: 'Point', coordinates: [10, -9] } }
    )

    expect(alarm.reload.spot.to_a).to eq([10, -9])
    expect(Alarm.within([10, -9], 1).to_a.map { |match| match.spot.to_a }).to eq([[10, -9]])
  end
end
