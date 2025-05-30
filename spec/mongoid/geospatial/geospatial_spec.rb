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
    let!(:jfk) do
      Bar.create!(name: 'jfk', location: [-73.77694444, 40.63861111])
    end

    let!(:lax) do
      Bar.create!(name: 'lax', location: [-118.40, 33.94])
    end

    it 'should work specifing center and different location lax' do
      expect(Bar.nearby(lax.location)).to eq([lax, jfk])
    end

    it 'should work specifing center and different location jfk' do
      expect(Bar.nearby(jfk.location)).to eq([jfk, lax])
    end

    it 'should work finding first' do
      expect(Bar.nearby(jfk.location).first).to eq(jfk)
    end

    it 'really should work find first nearby' do
      aa = Bar.create!(name: 'aa', location: [1, 1])
      bb = Bar.create!(name: 'bb', location: [2, 2])
      cc = Bar.create!(name: 'cc', location: [3, 3])
      expect(Bar.count).to eq(5)
      expect(Bar.nearby([1, 1]).to_a).to eq([aa, bb, cc, jfk, lax])
      expect(Bar.nearby([2, 2]).to_a.first).to eq(bb)
      # THIS WILL FAIL MONGOID ISSUE
      # expect(Bar.nearby(lax.location).first).to eq(lax)
    end

    it 'should work specifing first' do
      bars = Bar.nearby(lax.location).to_a
      expect(bars.first).to eq(lax)
    end

    it 'should work specifing first' do
      expect(Bar.nearby(lax.location).to_a.first).to eq(lax)
    end

    it 'should work specifing first' do
      expect(Bar.nearby(lax.location).first).to eq(lax)
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
          Alarm.create(spot: [rand(10) + 1, rand(10) + 1])
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
end
