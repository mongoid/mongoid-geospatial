# frozen_string_literal: true

#
# Mongoid fields extension
#
# field :foo, :spatial => true
#
Mongoid::Fields.option :spatial do |model, field, _options|
  # options = {} unless options.kind_of?(Hash)

  model.class_eval do
    spatial_fields << field.name.to_sym
    spatial_fields_indexed << field.name.to_sym

    # Create 2D index
    spatial_index field.name
  end
end
