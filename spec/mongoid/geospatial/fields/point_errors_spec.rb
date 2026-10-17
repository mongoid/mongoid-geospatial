# frozen_string_literal: true

require 'spec_helper'

describe Mongoid::Geospatial::Point do
  it 'rejects objects that cannot provide coordinates' do
    expect { described_class.mongoize(Object.new) }.to raise_error(RuntimeError, 'Invalid Point')
  end

  it 'reports a missing horizontal coordinate' do
    expect { described_class.mongoize(y: 1, unrelated: 2) }.to raise_error(RuntimeError, /Hash must contain/)
  end

  it 'reports a missing vertical coordinate' do
    expect { described_class.mongoize(x: 1, unrelated: 2) }.to raise_error(RuntimeError, /Hash must contain/)
  end
end
