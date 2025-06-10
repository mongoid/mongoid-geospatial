# frozen_string_literal: true

require 'spec_helper'

describe Mongoid::Fields do
  context 'delegate' do
    before do
      Bus.create_indexes
    end

    context 'x, y helpers' do
      let(:bus) { Bus.create!(name: 'Far', location: [7, 8]) }

      it 'should set instance method x' do
        expect(bus.x).to eq(7)
      end

      it 'should set instance method y' do
        expect(bus.y).to eq(8)
      end

      it 'should set instance method x=' do
        bus.x = 9
        expect(bus.x).to eq(9)
      end

      it 'should set instance method y=' do
        bus.y = 9
        expect(bus.y).to eq(9)
      end
    end

    it 'should set instance methods x= and y=' do
      bus = Bus.create!(name: 'B', location: [7, 7])
      bus.x = 8
      bus.y = 9
      expect(bus.location.to_a).to eq([8, 9])
    end

    it 'should work fine with default values' do
      event = Event.create!(name: 'Bvent')
      event.x = 8
      event.y = 9
      expect(event.location.to_a).to eq([8, 9])
    end

    it 'should not work fine with nils' do
      bus = Bus.create!(name: 'B', location: nil)
      expect do
        bus.x = 9
        bus.y = 9
      end.to raise_error(NoMethodError)
    end

    it 'should update point x' do
      bus = Bus.create!(name: '0789', location: [1, 1])
      bus.x = 2
      expect(bus.save).to be_truthy
      expect(Bus.first.location.to_a).to eq([2, 1])
    end

    it 'should update point y' do
      bus = Bus.create!(name: '0987', location: [1, 1])
      bus.y = 2
      expect(bus.save).to be_truthy
      expect(Bus.first.location.to_a).to eq([1.0, 2.0])
    end
  end
end
