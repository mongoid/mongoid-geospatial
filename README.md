Mongoid Geospatial
==================

A Mongoid Extension that simplifies the use of MongoDB spatial features.

[![Gem Version](https://badge.fury.io/rb/mongoid-geospatial.svg)](http://badge.fury.io/rb/mongoid-geospatial)
[![Code Climate](https://codeclimate.com/github/mongoid/mongoid-geospatial.svg)](https://codeclimate.com/github/mongoid/mongoid-geospatial)
[![Coverage Status](https://coveralls.io/repos/github/mongoid/mongoid-geospatial/badge.svg?branch=master)](https://coveralls.io/github/mongoid/mongoid-geospatial?branch=master)
[![Build Status](https://travis-ci.org/mongoid/mongoid-geospatial.svg?branch=master)](https://travis-ci.org/mongoid/mongoid-geospatial)

Quick Start
-----------

This gem focuses on (making helpers for) MongoDB's spatial features using Mongoid 5, 6 and 7.

```ruby
# Gemfile
gem 'mongoid-geospatial'
```

A `Place` to illustrate `Point`, `Line` and `Polygon`

```ruby
class Place
  include Mongoid::Document

  # Include the module
  include Mongoid::Geospatial

  # Just like mongoid,
  field :name,     type: String

  # define your field, but choose a geometry type:
  field :location, type: Point
  field :route,    type: LineString
  field :area,     type: Polygon

  # To query on your points, don't forget to index:
  # You may use a method:
  sphere_index :location  # 2dsphere
  # or
  spatial_index :location # 2d

  # Or use a helper directly on the `field`:
  field :location, type: Point, spatial: true  # 2d
  # or
  field :location, type: Point, sphere: true   # 2dsphere
end
```

Generate indexes on MongoDB via rake:

```
rake db:mongoid:create_indexes
```

Or programatically:

```ruby
Place.create_indexes
```

Points
------

This gem defines a specific `Point` class under the Mongoid::Geospatial namespace. Make sure to use `type: ::Mongoid::Geospatial::Point` to avoid name errors or collisions with other `Point` classes you might already have defined `NameError`s.

Currently, MongoDB supports query operations on 2D points only, so that's what this lib does. All geometries apart from points are just arrays in the database. Here's is how you can input a point as:

* longitude latitude array in that order - [long,lat] ([x, y])
* an unordered hash with latitude key(:lat, :latitude) and a longitude key(:lon, :long, :lng, :longitude)
* an ordered hash with longitude as the first item and latitude as the second item; this hash does not have include the latitude and longitude keys
* anything with the a method #to_xy or #to_lng_lat that converts itself to  [long, lat] array

_Note: the convention of having longitude as the first coordinate may vary for other libraries. For instance, Google Maps often refer to "LatLng". Make sure you keep those differences in mind. See below for how to configure this library for LatLng._

We store data in the DB as a [x, y] array then reformat when it is returned to you

```ruby
cafe = Place.create(
  name: 'Café Rider',
  location: {:lat => 44.106667, :lng => -73.935833},
  # or
  location: {latitude: 40.703056, longitude: -74.026667}
  #...
```

Now to access this spatial information we can do this

```ruby
cafe.location  # => [-74.026667, 40.703056]
```

If you need a hash

```ruby
cafe.location.to_hsh   # => { x: -74.026667, y: 40.703056 }
```

If you are using GeoRuby or RGeo

```ruby
cafe.location.to_geo   # => GeoRuby::Point

cafe.location.to_rgeo  # => RGeo::Point
```

Conventions:

This lib uses #x and #y everywhere.
It's shorter than lat or lng or another variation that also confuses.
A point is a 2D mathematical notation, longitude/latitude is when you use that notation to map an sphere. In other words: all longitudes are 'xs' where not all 'xs' are longitudes.

Distance and other geometrical calculations are delegated to the external library of your choice. More info about using RGeo or GeoRuby below. Some built in helpers for mongoid queries:

```ruby
# Returns middle point + radius
# Useful to search #within_circle
cafe.location.radius(5)        # [[-74.., 40..], 5]
cafe.location.radius_sphere(5) # [[-74.., 40..], 0.00048..]

# Returns hash if needed
cafe.location.to_hsh              # {:x => -74.., :y => 40..}
cafe.location.to_hsh(:lon, :lat)  # {:lon => -74.., :lat => 40..}
```

And for polygons and lines:

```ruby
house.area.bbox    # Returns polygon bounding_box (envelope)
house.area.center  # Returns calculate middle point
```

Model Setup
-----------

You can create Point, Line, Circle, Box and Polygon on your models:

```ruby
class CrazyGeom
  include Mongoid::Document
  include Mongoid::Geospatial

  field :location,  type: Point, spatial: true, delegate: true

  field :route,     type: Line
  field :area,      type: Polygon

  field :square,    type: Box
  field :around,    type: Circle

  # default mongodb options
  spatial_index :location, {bit: 24, min: -180, max: 180}

  # query by location
  spatial_scope :location
end
```

Helpers
-------

You can use `spatial: true` to add a '2d' index automatically,
No need for `spatial_index :location`:

```ruby
field :location,  type: Point, spatial: true
```

And you can use `sphere: true` to add a '2dsphere' index automatically, no need for `spatial_sphere :location`:

```ruby
field :location,  type: Point, sphere: true
```

You can delegate some point methods to the instance itself:

```ruby
field :location,  type: Point, delegate: true
```

Now instead of `instance.location.x` you may call `instance.x`.

Nearby
------

You can add a `spatial_scope` on your models. So you can query:

```ruby
Bar.nearby(my.location)
```

instead of

```ruby
Bar.near(location: my.location)
```

Good when you're drunk. Just add to your model:

```ruby
spatial_scope :<field>
```

Geometry
--------

You can also store Circle, Box, Line (LineString) and Polygons.
Some helper methods are available to them:

```ruby
# Returns a geometry bounding box
# Useful to query #within_geometry
polygon.bbox
polygon.bounding_box

# Returns a geometry calculated middle point
# Useful to query for #near
polygon.center

# Returns middle point + radius
# Useful to search #within_circle
polygon.radius(5)        # [[1.0, 1.0], 5]
polygon.radius_sphere(5) # [[1.0, 1.0], 0.00048..]
```

Query
-----

Before you proceed, make sure you have read this:

http://mongoid.github.io/old/en/origin/docs/selection.html#standard

All MongoDB queries are handled by Mongoid/Origin.

http://www.rubydoc.info/github/mongoid/origin/Origin/Selectable

You can use Geometry instance directly on any query:

* near

```ruby
Bar.near(location: person.house)
Bar.where(:location.near => person.house)
```

* near_sphere

```ruby
Bar.near_sphere(location: person.house)
Bar.where(:location.near_sphere => person.house)
```

* within_polygon

```ruby
Bar.within_polygon(location: [[[x,y],...[x,y]]])
# or with a bbox
Bar.within_polygon(location: street.bbox)
```

* intersects_line
* intersects_point
* intersects_polygon


External Libraries
------------------

We currently support GeoRuby and RGeo.
If you require one of those, a #to_geo and #to_rgeo, respectivelly,
method(s) will be available to all spatial fields, returning the
external library corresponding object.

### Use RGeo?

https://github.com/dazuma/rgeo

RGeo is a Ruby wrapper for Proj/GEOS.
It's perfect when you need to work with complex calculations and projections.
It'll require more stuff installed to compile/work.

### Use GeoRuby?

https://github.com/nofxx/georuby

GeoRuby is a pure Ruby Geometry Library.
It's perfect if you want simple calculations and/or keep your stack in pure ruby.
Albeit not full featured in maths it has a handful of methods and good import/export helpers.

### Example

```ruby
class Person
  include Mongoid::Document
  include Mongoid::Geospatial

  field :location, type: Point
end

me = Person.new(location: [8, 8])

# Example with GeoRuby
point.class # Mongoid::Geospatial::Point
point.to_geo.class # GeoRuby::SimpleFeatures::Point

# Example with RGeo
point.class # Mongoid::Geospatial::Point
point.to_rgeo.class # RGeo::Geographic::SphericalPointImpl
```

## Configure

Assemble it as you need (use a initializer file):

With RGeo

```ruby
Mongoid::Geospatial.with_rgeo!
# Optional
# Mongoid::Geospatial.factory = RGeo::Geographic.spherical_factory
```

With GeoRuby

```ruby
Mongoid::Geospatial.with_georuby!
```

By default the convention of this library is LngLat, configure it for LatLng as follows.

```ruby
Mongoid::Geospatial.configure do |config|
  config.point.x = Mongoid::Geospatial.lat_symbols
  config.point.y = Mongoid::Geospatial.lng_symbols
end
```

You will need to manually migrate any existing `Point` data if you change configuration in an existing system.

This Fork
---------

This fork is not backwards compatible with 'mongoid_spacial'.
This fork delegates calculations to external libs.

Change in your models:

```ruby
include Mongoid::Spacial::Document
```

to

```ruby
include Mongoid::Geospatial
```

And for the fields:

```ruby
field :source,  type: Array,    spacial: true
```

to

```ruby
field :source,  type: Point,    spatial: true # or sphere: true
```

Beware the 't' and 'c' issue. It's spaTial.

Troubleshooting
---------------

**Mongo::OperationFailure: can't find special index: 2d**

Indexes need to be created. Execute command:

```
rake db:mongoid:create_indexes
```

Programatically

```
Model.create_indexes
```

Contributing
------------

See [CONTRIBUTING](CONTRIBUTING.md).

License
-------

Copyright (c) 2009-2017 Mongoid Geospatial Authors

MIT License, see [MIT-LICENSE](MIT-LICENSE).

