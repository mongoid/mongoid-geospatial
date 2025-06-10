# frozen_string_literal: true

#
# Mongoid Geospatial Guardfile
#
ignore(%r{/.#.+})

# notification :off

guard :rubocop, all_on_start: false, keep_failed: false, notification: false, cli: ['--format', 'emacs'] do
  watch(%r{^lib/(.+)\.rb$})
end

guard :rspec, cmd: 'bundle exec rspec', notification: true do
  watch(%r{^spec/.+_spec\.rb$})
  watch(%r{^lib/(.+)\.rb$}) { |m| "spec/#{m[1]}_spec.rb" }
  watch('spec/spec_helper.rb') { 'spec' }
end
