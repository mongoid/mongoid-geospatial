## Unreleased

* Fix: `Point#==` was object identity, so the same `[x, y]` loaded twice was
  never equal (`place.geom == city.geom` false for one spot). `==`, `eql?`
  and `hash` now compare the stored pair; a Point never equals an Array.

## 7.3.0 (2026/09/17)

`within` did not work. 7.2's headline — a km cap — asked `$nearSphere` for
GeoJSON metres whatever the field was, and a field declared `spatial: true`
has no 2dsphere index to answer with. The spec passed because it asserted the
selector and never sent it, and because the model it asked carried both
indexes by accident.

```
   sphere: true    $nearSphere: { $geometry: {..}, $maxDistance: <metres> }   ok
   spatial: true   same                                    NoQueryExecutionPlans
                   $nearSphere: [x, y], $maxDistance: <km / 6371>            ok
```

* Fix: `within` / `nearby(km:)` raised `NoQueryExecutionPlans` on every field declared `spatial: true` — the field's index now picks the dialect, radians for a 2d one
* `Mongoid::Geospatial.near_selector(field, point, km, sphere:)` — the one place both wire shapes are built
* `within` / `nearest` / `nearby` take `field:` — a model with two pins (`geom :pick_up`, `geom :drop_up`) could only ever query the first one, silently, and naming a field it has no pin for now says so
* `Model.nearest(geom, km)` — the closest one, or nil. `within(geom, km).first` is **not** it: Mongoid's `#first` sorts by `_id` when the criteria has no sort of its own, which replaces the distance order `$near` put there
* Fix: `within(geom, nil)` ran an **uncapped** query instead of raising; `nearby` no longer swallows unknown keywords (`kilometres: 30` was a silent full scan)
* Fix: `near_query(geom, nil)` was a `NoMethodError` and a negative km went to the server — `ArgumentError` for both
* Fix: `spatial_fields_indexed` answered `[:spot, "spot"]` — one field, one entry, always a Symbol
* Fix: `Point.mongoize` could not read the GeoJSON `to_geo_json` writes, which `geo_near` documented as valid input
* Fix: `Point.mongoize("1 2 3")` stored three coordinates where `[1, 2, 3]` stored two
* Fix: `bbox` / `center` / `radius` on an empty geometry answered `[[MAX, MAX], [-MAX, -MAX]]` and a plausible-looking `[0.0, 0.0]` — `nil` now
* Fix: `Config.point.x` handed out the module's own array, so pushing to it edited `Mongoid::Geospatial.lng_symbols`
* Fix: `Point#[]` and `#distance` raise `ArgumentError` as documented, not `NoMethodError`, on a half-read point
* Fix: `radius_sphere(1, :nope)` was a `nil` division — `KeyError` names the unit
* Docs: `geo_near` returns the raw aggregation — `BSON::Document` hashes, never model instances. The README and the `@return` both promised documents with `.distance`; the example raised `NoMethodError`
* Docs: `Point#to_lat_lon` keys are `:latitude` / `:longitude`, not `:lat` / `:lon`
* `mongoid` floor is `>= 7.0.0`: `Symbol.add_key(name, :override, ...)` is the post-Origin signature, so a 4/5/6 install resolved and then broke at load
* Deleted `spec/.../helpers/core_spec.rb` — no examples, and it defined four broken methods onto the module under test

## 7.2.0 (2026/09/17)

* `Model.within(geom, km)` / `nearby(coords, km:)` — `$nearSphere` capped in kilometres
* `Mongoid::Geospatial::Geom` / `geom` — the pin (`geom`, 2dsphere); `geom :pick_up` names another
* `Mongoid::Geospatial.near_query` — the selector, when you do not own the model
* `Point#distance` — haversine in km (or `:m`, `:mi`, `:ft`, `:sm`)
* `Point#lat` / `#lng`, `geo_near(..., km:)`
* Fix: `geo_near` read `:km` as radians on a legacy pair — it sends GeoJSON on a sphere now
* Fix: `geo_near` pinned `spherical` to true whatever the caller asked for
* `:field.within_circle` / `:field.within_spherical_circle` — the `$geoWithin` circles Mongoid dropped
* Fix: a half-read coordinate (`"nowhere"` mongoizes to `[0.0]`) raises instead of querying

## 5.1.0 (2018/11/09)

* [#61](https://github.com/mongoid/mongoid-geospatial/pull/64): Add global configuration for switching between LngLat and LatLng - [@dblock](https://github.com/dblock).
* [#59](https://github.com/mongoid/mongoid-geospatial/pull/59), [#65](https://github.com/mongoid/mongoid-geospatial/pull/65): Test against Mongoid 5, 6 and 7 - [@dblock](https://github.com/dblock).
* [#52](https://github.com/mongoid/mongoid-geospatial/pull/52), [#70](https://github.com/mongoid/mongoid-geospatial/pull/70): Added Danger and Rubocop, PR and code linters - [@dblock](https://github.com/dblock).

## 5.0.0 (2015/07/23)

* Mongoid 5 support - [@nofxx](https://github.com/nofxx).

## 4.0.1 (2015/03/04)

## 4.0.0 (2015/01/11)

* Mongoid 4 support - [@nofxx](https://github.com/nofxx).

## 3.9.0 (2014/12/22)

* Initial public release - [@nofxx](https://github.com/nofxx).
