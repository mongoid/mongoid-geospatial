# Sample spec class
class Person
  include Mongoid::Document
  include Mongoid::Timestamps
  # include Mongoid::Versioning
  include Mongoid::Geospatial

  attr_accessor :mode

  class_attribute :somebody_elses_important_class_options
  self.somebody_elses_important_class_options = { keep_me_around: true }

  field :ssn
  field :title
  field :terms,      type: Boolean
  field :pets,       type: Boolean, default: false
  field :age,        type: Integer, default: 100
  field :dob,        type: Date
  field :lunch_time, type: Time
  field :aliases,    type: Array
  field :map,        type: Hash
  field :score,      type: Integer
  field :owner_id,   type: Integer
  field :reading,    type: Object
  # field :bson_id,    type: bson_object_id_class
  field :employer_id
  field :security_code
  field :blood_alcohol_content, type: Float, default: -> { 0.0 }
  field :last_drink_taken_at,   type: Date,
                                default: -> { 1.day.ago.in_time_zone('Alaska') }

  # Geo
  field :location, type: Point

  index age: 1
  index addresses: 1
  index dob: 1
  index name: 1
  index title: 1
  index({ ssn: 1 }, unique: true)

  validates_format_of :ssn, without: /\$\$\$/

  attr_reader :rescored

  # attr_protected :security_code, :owner_id

  embeds_many :addresses, as: :addressable do
    def extension
      'Testing'
    end

    def find_by_street(street)
      @target.select { |doc| doc.street == street }
    end
  end

  accepts_nested_attributes_for :addresses

  scope :minor, -> { where(:age.lt => 18) }
  scope :without_ssn, -> { without(:ssn) }

  def update_addresses
    addresses.each do |address|
      address.street = 'Updated Address'
    end
  end

  def employer=(emp)
    self.employer_id = emp.id
  end

  class << self
    def accepted
      criteria.where(terms: true)
    end

    def knight
      criteria.where(title: 'Sir')
    end

    def old
      criteria.where(age: { '$gt' => 50 })
    end
  end
end

# Inheritance test
class Doctor < Person
  field :specialty
end
