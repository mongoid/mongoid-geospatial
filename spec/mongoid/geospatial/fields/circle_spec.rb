# frozen_string_literal: true

require 'spec_helper'

describe Mongoid::Geospatial::Circle do
  let(:center_coords) { [1, 2] }
  let(:radius_value) { 3 }
  let(:circle_data) { [center_coords, radius_value] }
  let(:alarm) { Alarm.new(radius: circle_data) }

  it 'instantiates a Circle object from an array representing center and radius' do
    expect(alarm.radius).to be_a Mongoid::Geospatial::Circle
  end

  it 'correctly stores and provides access to the center point' do
    expect(alarm.radius.center).to be_a Mongoid::Geospatial::Point
    expect(alarm.radius.center.x).to eq(center_coords[0])
    expect(alarm.radius.center.y).to eq(center_coords[1])
  end

  it 'correctly stores and provides access to the radius value' do
    expect(alarm.radius.radius).to eq(radius_value)
  end

  it 'correctly stores the assigned data as an array' do
    # The underlying storage is still an array [center_array, radius_val]
    expect(alarm.radius.to_a).to eq(circle_data)
  end
end
