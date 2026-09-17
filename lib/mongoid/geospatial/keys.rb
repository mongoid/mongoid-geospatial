# frozen_string_literal: true

#
# `$geoWithin` with a circle. Mongoid ships `within_polygon` and `within_box`
# and stopped there — the two circle shapes left with Origin, and `Point#radius`
# / `#radius_sphere` have been building their argument ever since.
#
#   Bar.where(:location.within_circle => elvis.location.radius(0.05))
#   Bar.where(:location.within_spherical_circle => elvis.location.radius_sphere(5, :km))
#
# `$center` reads its radius in the coordinate system's own units (degrees, for
# a legacy pair); `$centerSphere` reads radians, which is what `radius_sphere`
# returns. Guarded: if Mongoid ever registers these, its own wins.
#
%i[within_circle within_spherical_circle].each do |name|
  next if Symbol.method_defined?(name)

  operator = name == :within_circle ? '$center' : '$centerSphere'
  Symbol.add_key(name, :override, '$geoWithin', operator)
end
