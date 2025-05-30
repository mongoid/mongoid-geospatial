Releasing Mongoid::Geospatial
=============================

There're no particular rules about when to release mongoid-geospatial. Release bug fixes frequently, features not so frequently and breaking API changes rarely.

### Release

Run tests, check that all tests succeed locally.

```
bundle install
bundle exec rake
```

Check that the last build succeeded in [Travis CI](https://travis-ci.org/mongoid/mongoid-geospatial) for all supported platforms.

Change "Next Release" in [CHANGELOG.md](CHANGELOG.md) to the new version.

```
### 0.4.0 (2014-01-27)
```

Remove the line with "Your contribution here.", since there will be no more contributions to this release.

Commit your changes.

```
git add CHANGELOG.md lib/mongoid/geospatial/version.rb
git commit -m "Preparing for release, 0.4.0."
git push origin master
```

Release.

```
$ rake release

mongoid-geospatial 0.4.0 built to pkg/mongoid-geospatial-0.4.0.gem.
Tagged v0.4.0.
Pushed git commits and tags.
Pushed mongoid-geospatial 0.4.0 to rubygems.org.
```

### Prepare for the Next Version

Add the next release to [CHANGELOG.md](CHANGELOG.md).

```
### 0.4.1 (Next)

* Your contribution here.
```

Increment the minor version, modify [lib/mongoid/geospatial/version.rb](lib/mongoid/geospatial/version.rb).

Commit your changes.

```
git add CHANGELOG.md lib/mongoid/geospatial/version.rb
git commit -m "Preparing for next developer iteration, 0.4.1."
git push origin master
```
