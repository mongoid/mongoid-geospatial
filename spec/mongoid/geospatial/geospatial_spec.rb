# frozen_string_literal: true

require 'spec_helper'

describe Mongoid::Geospatial do
  context 'Class Stuff' do
    it 'should have an lng_symbols accessor' do
      expect(Mongoid::Geospatial.lng_symbols).to be_instance_of Array
      expect(Mongoid::Geospatial.lng_symbols).to include :x
    end

    it 'should have an lat_symbols accessor' do
      expect(Mongoid::Geospatial.lat_symbols).to be_instance_of Array
      expect(Mongoid::Geospatial.lat_symbols).to include :y
    end
  end

  context 'Creating indexes' do
    it 'should create a 2d index' do
      Bar.create_indexes
      expect(Bar.collection.indexes.get(location: '2d')).not_to be_nil
    end

    it 'should create a 2dsphere index' do
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

    it 'should work specifing center and different location foo' do
      expect(Bar.nearby(foo.location)).to be_a Mongoid::Criteria
      expect(Bar.nearby(foo.location).selector).to eq({ 'location' => { '$near' => [3.0, 3.0] } })
    end

    it 'should work specifing center and different location moes' do
      expect(Bar.nearby(moes.location).limit(2)).to eq([moes, rose])
    end

    it 'should work finding first' do
      expect(Bar.nearby(moes.location).first).to eq(moes)
    end

    it 'really should work find first nearby' do
      expect(Bar.count).to eq(4)
      expect(Bar.nearby([1, 1]).to_a).to eq([jane, foo, moes, rose])
      expect(Bar.nearby([2, 2]).to_a.first).to eq(jane)
    end

    it 'should work specifing first' do
      bars = Bar.nearby(rose.location).to_a
      expect(bars.first).to eq(rose)
      pending 'MongoDB issue, dont use first or last!'
      expect(Bar.nearby(rose.location).first).to eq(rose) # Consolidated from other similar tests
    end

    it 'should work specifing last' do
      bars = Bar.nearby(rose.location).to_a
      expect(bars.last).to eq(foo)
      expect(Bar.nearby(rose.location).last).to eq(foo) # Consolidated from other similar tests
    end

    it 'returns the documents sorted closest to furthest' do
      expect(Bar.closest_to_location(rose.location).to_a)
        .to eq([rose, moes, jane, foo])
    end

    it 'returns the documents sorted closest to furthest with limit' do
      expect(Bar.closest_to_location(rose.location).limit(2))
        .to eq([rose, moes])
    end

    it 'returns the first document when sorted closest to furthest' do
      bars = Bar.closest_to_location(rose.location).to_a
      expect(bars.first).to eq(rose)
    end

    it 'returns the first document when sorted closest to furthest' do
      pending 'MongoDB issue, dont use first or last!'
      expect(Bar.closest_to_location(rose.location).first).to eq(rose)
    end

    it 'should work specifing center and different location foo for closest_to_location' do
      expect(Bar.closest_to_location(foo.location)).to be_a Mongoid::Criteria
      expect(Bar.closest_to_location(foo.location).selector).to eq({ 'location' => { '$near' => [3.0, 3.0] } })
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

    it 'should work with specific center and different spot attribute' do
      expect(Alarm.nearby(lax.spot)).to eq([lax, jfk])
    end

    it 'should work with default origin' do
      expect(Alarm.near_sphere(spot: lax.spot)).to eq([lax, jfk])
    end

    it 'should work with default origin key' do
      expect(Alarm.where(:spot.near_sphere => lax.spot)).to eq([lax, jfk])
    end

    context ':paginate' do
      before do
        Alarm.create_indexes
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
        Alarm.create_indexes
        3.times do
          Alarm.create(spot: [jfk.spot.x + rand(0), jfk.spot.y + rand(0)])
        end
      end

      it 'should filter using extra query option' do
        query = Alarm.near_sphere(spot: jfk.spot).where(name: jfk.name)
        expect(query.to_a).to eq [jfk]
      end
    end

    context ':maxDistance' do
      it 'should get 1 item' do
        spot = 2465 / Mongoid::Geospatial.earth_radius[:mi]
        query = Alarm.near_sphere(spot: lax.spot).max_distance(spot: spot)
        expect(query.to_a.size).to eq 1
      end
    end

    #     context ':distance_multiplier' do
    #       it "should multiply returned distance with multiplier" do
    #         Bar.geo_near(lax.location,
    #         ::distance_multiplier=> Mongoid::Geospatial.earth_radius[:mi])
    #            .second.geo[:distance].to_i.should be_within(1).of(2469)
    #       end
    #     end

    #     context ':unit' do
    #       it "should multiply returned distance with multiplier" do
    #         Bar.geo_near(lax.location, :spherical => true, :unit => :mi)
    #           .second.geo[:distance].to_i.should be_within(1).of(2469)
    #       end

    #       it "should convert max_distance to radians with unit" do
    #         Bar.geo_near(lax.location, :spherical => true,
    #          :max_distance => 2465, :unit => :mi).size.should == 1
    #       end

    #     end

    #   end

    #   context 'criteria chaining' do
    #     it "should filter by where" do
    #       Bar.where(:name => jfk.name).geo_near(jfk.location).should == [jfk]
    #       Bar.any_of({:name => jfk.name},{:name => lax.name})
    #         .geo_near(jfk.location).should == [jfk,lax]
    #     end
    #   end
    # end
  end

  context '#geo_near' do
    before do
      Bar.create_indexes
      bar1 = Bar.create!(name: 'Bar1', location: [10, 20])
      bar2 = Bar.create!(name: 'Bar2', location: [10.1, 20.1])
      bar3 = Bar.create!(name: 'Bar3', location: [21, 21])
      @bars = [bar1, bar2, bar3]
    end
          #   # Find places near [10, 20], using spherical calculations, up to 5km away
      #   Place.geo_near(:location, [10, 20],
      #                  spherical: true,
      #                  maxDistance: 5000, # 5 kilometers in meters
      #                  distanceField: 'dist.calculated',
      #                  query: { category: 'restaurant' },
      #                  limit: 10)
      #
      #   # Iterate over results
      #   Place.geo_near(:location, [10, 20], spherical: true).each do |place|
      #     puts "#{place.name} is #{place.distance} meters away." # Assumes distanceField is 'distance'
      #   end
    it 'should return places near a point' do
      expect(Bar.geo_near(:location, [10, 20]).to_a).to eq(@bars)
    end
  end
end
