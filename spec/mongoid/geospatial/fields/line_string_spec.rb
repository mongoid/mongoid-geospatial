require 'spec_helper'

describe Mongoid::Geospatial::LineString do
  describe '(de)mongoize' do
    it 'should support a field mapped as linestring' do
      river = River.new(course: [[5, 5], [6, 5], [6, 6], [5, 6]])
      expect(river.course).to be_a Mongoid::Geospatial::LineString
      expect(river.course).to eq([[5, 5], [6, 5], [6, 6], [5, 6]])
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

    it 'should support a field mapped as linestring' do
      River.create!(course: [[5, 5], [6, 5], [6, 6], [5, 6]])
      expect(River.first.course).to eq([[5, 5], [6, 5], [6, 6], [5, 6]])
    end

    it 'should have a bounding box' do
      l = Mongoid::Geospatial::LineString.new [[1, 5], [6, 5], [6, 6], [5, 6]]
      expect(l.bbox).to eq([[1, 5], [6, 6]])
    end

    it 'should have a geom box' do
      l = Mongoid::Geospatial::LineString.new [[1, 1], [5, 5]]
      expect(l.geom_box).to eq([[1, 1], [1, 5], [5, 5], [5, 1], [1, 1]])
    end

    it 'should have a geom box' do
      l = Mongoid::Geospatial::LineString.new [[1, 1], [2, 2], [3, 4], [5, 5]]
      expect(l.geom_box).to eq([[1, 1], [1, 5], [5, 5], [5, 1], [1, 1]])
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
