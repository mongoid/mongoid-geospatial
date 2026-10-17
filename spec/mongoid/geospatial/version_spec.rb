# frozen_string_literal: true

require 'spec_helper'

describe Mongoid::Geospatial do
  it 'defines a semantic version' do
    expect(described_class::VERSION).to match(/\A\d+\.\d+\.\d+\z/)
  end
end
