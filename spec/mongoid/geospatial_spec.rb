# frozen_string_literal: true

require 'spec_helper'

describe Mongoid::Geospatial do
  context 'Class Stuff' do
    it 'has an lng_symbols accessor' do
      expect(Mongoid::Geospatial.lng_symbols).to be_instance_of Array
      expect(Mongoid::Geospatial.lng_symbols).to include :x
    end

    it 'has an lat_symbols accessor' do
      expect(Mongoid::Geospatial.lat_symbols).to be_instance_of Array
      expect(Mongoid::Geospatial.lat_symbols).to include :y
    end
  end

  context 'Creating indexes' do
    it 'creates a 2d index' do
      Bar.create_indexes
      expect(Bar.collection.indexes.get(location: '2d')).not_to be_nil
    end

    it 'creates a 2dsphere index' do
      Alarm.create_indexes
      expect(Alarm.collection.indexes.get(spot: '2dsphere')).not_to be_nil
    end
  end

  context '#nearby 2d' do
    before do
      Bar.create_indexes
    end
    after do
      Bar.collection.indexes.drop_all
    end

    let!(:moes) do
      Bar.create!(name: "Moe's", location: [-73.77694444, 40.63861111])
    end

    let!(:rose) do
      Bar.create!(name: 'Rosa', location: [-118.40, 33.94])
    end

    let!(:jane) do
      Bar.create!(name: "Jane's", location: [1, 1])
    end

    let!(:foo) do
      Bar.create!(name: 'Foo', location: [3, 3])
    end

    it 'builds the same $near selector as its spatial_scope' do
      expect(Bar.nearby(foo.location)).to be_a Mongoid::Criteria
      expect(Bar.nearby(foo.location).selector)
        .to eq({ 'location' => { '$near' => [3.0, 3.0] } })
      expect(Bar.closest_to_location(foo.location).selector)
        .to eq(Bar.nearby(foo.location).selector)
    end

    it 'orders every document by distance from the point given' do
      expect(Bar.nearby([1, 1]).to_a).to eq([jane, foo, moes, rose])
      expect(Bar.nearby(rose.location).to_a).to eq([rose, moes, jane, foo])
      expect(Bar.closest_to_location(rose.location).to_a).to eq([rose, moes, jane, foo])
    end

    it 'keeps that order under limit' do
      expect(Bar.nearby(moes.location).limit(2)).to eq([moes, rose])
      expect(Bar.closest_to_location(rose.location).limit(2)).to eq([rose, moes])
    end

    # Not a MongoDB issue: Mongoid's #first and #last sort by _id when the
    # criteria carries no sort of its own (contextual/mongo.rb, `view.sort ||
    # { _id: 1 }`), and that _id sort replaces the distance order $near put
    # there. Walk the criteria — `.to_a.first` — or ask $geoNear, which
    # returns the distance as a field you can sort on.
    #
    # It reads as working whenever the nearest document happens to be the
    # oldest: `nearby(moes.location).first` is Moe's either way. Rosa is the
    # example that tells the truth.
    it 'loses the $near order to #first and #last — read the criteria instead' do
      expect(Bar.nearby(rose.location).to_a.first).to eq(rose)
      expect(Bar.nearby(rose.location).first).to eq(Bar.asc(:_id).first)
      expect(Bar.nearby(rose.location).last).to eq(Bar.desc(:_id).first)
    end
  end

  context '#nearby 2dsphere' do
    before do
      Alarm.create_indexes
    end
    after do
      Alarm.collection.indexes.drop_all
    end
    let!(:jfk) do
      Alarm.create(name: 'jfk', spot: [-73.77694444, 40.63861111])
    end

    let!(:lax) do
      Alarm.create(name: 'lax', spot: [-118.40, 33.94])
    end

    it 'answers the same through nearby, the macro and the symbol key' do
      expect(Alarm.nearby(lax.spot)).to eq([lax, jfk])
      expect(Alarm.near_sphere(spot: lax.spot)).to eq([lax, jfk])
      expect(Alarm.where(:spot.near_sphere => lax.spot)).to eq([lax, jfk])
    end

    context ':paginate' do
      before do
        50.times do
          Alarm.create(spot: [rand(1..10), rand(1..10)])
        end
      end

      it 'limits fine with 25' do
        expect(Alarm.near_sphere(spot: [5, 5])
                .limit(25).to_a.size).to eq 25
      end

      it 'limits fine with 25 and skips' do
        expect(Alarm.near_sphere(spot: [5, 5])
                .skip(25).limit(25).to_a.size).to eq 25
      end

      it 'paginates 50' do
        page1 = Alarm.near_sphere(spot: [5, 5]).limit(25)
        page2 = Alarm.near_sphere(spot: [5, 5]).skip(25).limit(25)
        expect((page1 + page2).uniq.size).to eq(50)
      end
    end

    context ':query' do
      before do
        3.times do
          Alarm.create(spot: [jfk.spot.x + rand, jfk.spot.y + rand])
        end
      end

      it 'filters using extra query option' do
        query = Alarm.near_sphere(spot: jfk.spot).where(name: jfk.name)
        expect(query.to_a).to eq [jfk]
      end
    end

    context ':maxDistance' do
      it 'gets 1 item' do
        spot = 2465 / Mongoid::Geospatial.earth_radius[:mi]
        query = Alarm.near_sphere(spot: lax.spot).max_distance(spot: spot)
        expect(query.to_a.size).to eq 1
      end
    end

    context '#within km' do
      it 'caps in kilometres' do
        expect(Alarm.within(lax.spot, 10)).to eq([lax])
        expect(Alarm.within(lax.spot, 5000)).to eq([lax, jfk])
      end

      it 'is the same question as nearby(km:)' do
        expect(Alarm.nearby(lax.spot, km: 10)).to eq([lax])
      end

      # The dialect comes off the field declaration, not off the caller.
      # Executed against both index kinds in helpers/nearby_spec.rb.
      it 'reads the dialect off the field, radians for a 2d one' do
        expect(Bar.nearby([1, 1], km: 1).selector['location'])
          .to eq('$nearSphere' => [1.0, 1.0],
                 '$maxDistance' => 1 / Mongoid::Geospatial::EARTH_RADIUS_KM.to_f)
        expect(Alarm.nearby([1, 1], km: 1).selector['spot']['$nearSphere'])
          .to have_key('$geometry')
      end

      it 'refuses a cap it cannot measure' do
        expect { Alarm.within(lax.spot, nil) }.to raise_error(ArgumentError)
        expect { Alarm.nearby(lax.spot, km: 0) }.to raise_error(ArgumentError)
      end

      it 'chains on a criteria' do
        expect(Alarm.where(name: 'jfk').within(jfk.spot, 10)).to eq([jfk])
      end
    end
  end

  context '#geo_near' do
    before do
      Bar.create_indexes
      # ~15km and ~1150km out from [10, 20].
      Bar.create!(name: 'Bar1', location: [10, 20])
      Bar.create!(name: 'Bar2', location: [10.1, 20.1])
      Bar.create!(name: 'Bar3', location: [21, 21])
      @query = Bar.geo_near(:location, [10, 20]).to_a
    end

    it 'returns places with distance near a point' do
      expect(@query.first['distance']).to be_zero
    end

    # $geoNear adds fields a Bar does not have. Nothing is instantiated —
    # the docs promise hashes, so hold them to it.
    it 'hands back hashes, not documents' do
      expect(@query.first).to be_a(Hash)
      expect(@query.first).not_to be_a(Mongoid::Document)
    end

    it 'caps with km, in metres, on the sphere' do
      names = Bar.geo_near(:location, [10, 20], km: 5).to_a.map { |b| b['name'] }
      expect(names).to eq(['Bar1'])
      expect(Bar.geo_near(:location, [10, 20], km: 50).to_a.size).to eq(2)
    end
  end
end
