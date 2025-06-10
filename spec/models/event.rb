# frozen_string_literal: true

# Sample spec class
class Event
  include Mongoid::Document
  include Mongoid::Geospatial

  field :name
  field :date, type: Date

  field :location, type: Point, delegate: true, default: [7, 7]

  def self.each_day(start_date, end_date)
    groups = only(:date).asc(:date)
                        .where(:date.gte => start_date, :date.lte => end_date).group
    groups.each do |hash|
      yield(hash['date'], hash['group'])
    end
  end
end
