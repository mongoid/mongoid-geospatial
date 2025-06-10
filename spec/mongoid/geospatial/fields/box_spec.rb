# frozen_string_literal: true

require 'spec_helper'

describe Mongoid::Geospatial::Box do
  let(:points) { [[1, 2], [3, 4]] }
  let(:alarm) { Alarm.new(area: points) }

  it 'instantiates a Box object from an array of points' do
    expect(alarm.area).to be_a Mongoid::Geospatial::Box
  end

  it 'correctly stores the assigned points' do
    expect(alarm.area.to_a).to eq(points)
  end

  it 'can calculate its bounding box using inherited methods' do
    # For a box defined by [[1,2], [3,4]], the bbox should be itself.
    # However, the #bounding_box method in GeometryField expects a list of individual points
    # and calculates min/max x and y.
    # If the Box is [[min_x, min_y], [max_x, max_y]]
    # or a list of points forming the box.
    # Given the current GeometryField#bounding_box, it will treat [[1,2],[3,4]] as two points.
    # min_x = 1, min_y = 2, max_x = 3, max_y = 4
    expect(alarm.area.bounding_box).to eq([[1, 2], [3, 4]])
  end

  it 'can calculate its center point using inherited methods' do
    # Center of [[1,2], [3,4]] is [(1+3)/2, (2+4)/2] = [2,3]
    expect(alarm.area.center).to eq([2.0, 3.0])
  end
end
