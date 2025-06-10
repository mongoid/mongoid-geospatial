# frozen_string_literal: true

# Sample spec class
class Phone
  include Mongoid::Document
  field :number

  embeds_one :country_code
  embedded_in :person
end
