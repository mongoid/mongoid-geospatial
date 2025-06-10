# frozen_string_literal: true

require 'spec_helper'

describe Mongoid::Geospatial::LineString do
  describe '(de)mongoize' do
    let(:initial_course_points) { [[5, 5], [6, 5], [6, 6], [5, 6]] }

    it 'should correctly (de)mongoize a LineString field' do
      # Test instantiation
      river1 = River.new(course: initial_course_points)
      expect(river1.course).to be_a Mongoid::Geospatial::LineString
      expect(river1.course).to eq(initial_course_points)

      # Test creation and retrieval
      River.create!(course: initial_course_points)
      retrieved_river = River.first
      expect(retrieved_river.course).to be_a Mongoid::Geospatial::LineString
      expect(retrieved_river.course).to eq(initial_course_points)
    end

    it 'should update line string too' do
      river = River.create!(name: 'Amazonas')
      river.course = [[1, 1], [1, 1], [9, 9], [9, 9]]
      river.save
      expect(River.first.course).to eq(river.course)
    end

    it 'should line_string += point nicely' do
      river = River.create!(name: 'Amazonas', course: [[1, 1], [9, 9]])
      river.course += [[10, 10]]
      river.save
      expect(River.first.course).to eq([[1, 1], [9, 9], [10, 10]])
    end

    it 'should NOT parent.line_string << point nicely (mongoid doesnt track <<)' do
      river = River.create!(name: 'Amazonas', course: [[1, 1], [9, 9]])
      river.course << [10, 10]
      river.save
      expect(River.first.course).to eq([[1, 1], [9, 9]])
    end

    it 'should have same obj id' do
      pending 'Mongoid Issue #...'
      river = River.create!(name: 'Amazonas', course: [[1, 1], [9, 9]])
      expect(river.course.object_id).to eq(river.course.object_id)
    end

    it 'should have same obj id ary' do
      river = River.create!(name: 'Amazonas', mouth_array: [[1, 1], [9, 9]])
      expect(river.mouth_array.object_id).to eq(river.mouth_array.object_id)
    end

    # This test is now covered by the consolidated '(de)mongoize' test above
    # it 'should support a field mapped as linestring' do
    #   River.create!(course: [[5, 5], [6, 5], [6, 6], [5, 6]])
    #   expect(River.first.course).to eq([[5, 5], [6, 5], [6, 6], [5, 6]])
    # end

    it 'should have a bounding box' do
      l = Mongoid::Geospatial::LineString.new [[1, 5], [6, 5], [6, 6], [5, 6]]
      expect(l.bbox).to eq([[1, 5], [6, 6]])
    end

    it 'should calculate geom_box correctly for different LineStrings' do
      l1 = Mongoid::Geospatial::LineString.new [[1, 1], [5, 5]]
      expect(l1.geom_box).to eq([[1, 1], [1, 5], [5, 5], [5, 1], [1, 1]])

      l2 = Mongoid::Geospatial::LineString.new [[1, 1], [2, 2], [3, 4], [5, 5]]
      # Bounding box for l2: min_x=1, min_y=1, max_x=5, max_y=5
      expect(l2.geom_box).to eq([[1, 1], [1, 5], [5, 5], [5, 1], [1, 1]])
    end

    it 'should have a center point' do
      l = Mongoid::Geospatial::LineString.new [[1, 1], [1, 1], [9, 9], [9, 9]]
      expect(l.center).to eq([5.0, 5.0])
    end

    it 'should have a radius helper' do
      l = Mongoid::Geospatial::LineString.new [[1, 1], [1, 1], [9, 9], [9, 9]]
      expect(l.radius(10)).to eq([[5.0, 5.0], 10])
    end

    it 'should have a radius sphere' do
      l = Mongoid::Geospatial::LineString.new [[1, 1], [1, 1], [9, 9], [9, 9]]
      expect(l.radius_sphere(10)[1]).to be_within(0.001).of(0.001569)
    end
  end
end
