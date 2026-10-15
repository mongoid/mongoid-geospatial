# frozen_string_literal: true

require 'spec_helper'

describe Mongoid::Geospatial::Point, '.demongoize' do
  it 'returns nil for nil or an empty array' do
    expect(described_class.demongoize(nil)).to be_nil
    expect(described_class.demongoize([])).to be_nil
  end

  it 'preserves coordinates, including zero and altitude' do
    point = described_class.demongoize([0, 0, 100])
    expect([point.x, point.y, point.z]).to eq([0, 0, 100])
  end

  it 'still rejects incomplete nonempty coordinates' do
    expect { described_class.demongoize([1]) }.to raise_error(ArgumentError)
  end

  context 'with an empty array stored in the database' do
    let(:person) do
      document = Person.create!(location: [1, 2])
      Person.collection.find(_id: document.id).update_one('$set' => { location: [] })
      Person.find(document.id)
    end

    it 'reads the point as nil without rewriting the stored value' do
      expect(person.location).to be_nil
      expect(Person.collection.find(_id: person.id).first['location']).to eq([])
    end

    it 'allows replacing the point with valid coordinates' do
      person.update!(location: [3, 4])
      expect(person.reload.location.to_a).to eq([3, 4])
    end

    it 'allows clearing the point' do
      person.update!(location: nil)
      expect(person.reload.location).to be_nil
      expect(Person.collection.find(_id: person.id).first['location']).to be_nil
    end
  end
end
