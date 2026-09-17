## 7.2.0 (2026/09/17)

* `Model.within(geom, km)` / `nearby(coords, km:)` — `$nearSphere` capped in kilometres
* `Mongoid::Geospatial::Geom` / `geom` — the pin (`geom`, 2dsphere); `geom :pick_up` names another
* `Mongoid::Geospatial.near_query` — the selector, when you do not own the model
* `Point#distance` — haversine in km (or `:m`, `:mi`, `:ft`, `:sm`)
* `Point#lat` / `#lng`, `geo_near(..., km:)`
* Fix: `geo_near` read `:km` as radians on a legacy pair — it sends GeoJSON on a sphere now
* Fix: `geo_near` pinned `spherical` to true whatever the caller asked for
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
