# frozen_string_literal: true

require 'spec_helper'

describe Mongoid::Geospatial do
  it 'defines its version from the standalone entry point' do
    hide_const('Mongoid::Geospatial::VERSION')
    begin
      load File.expand_path('../../../lib/mongoid/geospatial/version.rb', __dir__)
      expect(described_class::VERSION).to match(/\A\d+\.\d+\.\d+\z/)
    ensure
      described_class.send(:remove_const, :VERSION) if described_class.const_defined?(:VERSION)
    end
  end
end
