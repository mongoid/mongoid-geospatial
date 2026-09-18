# frozen_string_literal: true

require 'spec_helper'

describe Mongoid::Fields do
  context 'spatial' do
    before do
      Alarm.create_indexes
    end

    it 'creates indexes' do
      expect(Alarm.collection.indexes.get(spot: '2dsphere')).not_to be_nil
    end

    it 'creates correct indexes' do
      expect(Alarm.collection.indexes.get(spot: '2dsphere'))
        .to include('2dsphereIndexVersion' => 3,
                    'background' => false,
                    'key' => { 'spot' => '2dsphere' },
                    'name' => 'spot_2dsphere',
                    'v' => 2)
    end

    it 'sets spatial fields' do
      expect(Alarm.spatial_fields).to eql([:spot])
    end

    it 'names each indexed field once' do
      expect(Alarm.spatial_fields_indexed).to eql([:spot])
    end

    it 'correctly instantiate the field type when a spherical index is defined' do
      far = Alarm.create!(name: 'Far', spot: [7, 7])
      expect(far.spot).to be_instance_of(Mongoid::Geospatial::Point)
    end
  end
end
