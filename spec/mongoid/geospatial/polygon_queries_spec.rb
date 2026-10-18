# frozen_string_literal: true

require 'spec_helper'

describe 'Polygon and bounding-box queries' do
  let!(:inside) { Bar.create!(name: 'inside', location: [1, 1]) }
  let!(:outside) { Bar.create!(name: 'outside', location: [3, 3]) }
  let(:ring) { [[0, 0], [2, 0], [2, 2], [0, 2], [0, 0]] }

  it 'finds points inside a polygon using the symbol operator' do
    expect(Bar.where(:location.within_polygon => [ring]).to_a).to eq([inside])
  end

  it 'chains a polygon query with other criteria' do
    expect(Bar.where(name: outside.name).where(:location.within_polygon => [ring]).to_a).to be_empty
  end

  it 'finds points inside a geometry bounding box using within_box' do
    street = Mongoid::Geospatial::LineString.new([[0, 0], [2, 2]])
    expect(Bar.where(:location.within_box => street.bbox).to_a).to eq([inside])
  end
end
