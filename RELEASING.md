# Releasing Mongoid::Geospatial

## Prepare

Start in the upstream checkout on a clean `master`, run `git pull --ff-only`, and verify the latest [GitHub Actions](https://github.com/mongoid/mongoid-geospatial/actions) checks pass. Choose a patch version for fixes, a minor version for backward-compatible features, or a major version for breaking changes.

Update `lib/mongoid/geospatial/version.rb` and date the corresponding section in `CHANGELOG.md` using `YYYY/MM/DD`. Remove its contribution placeholder. Do not include changes already published in an earlier gem.

```sh
bundle install
bundle exec rake
git add CHANGELOG.md lib/mongoid/geospatial/version.rb RELEASING.md
git commit -m "Preparing for release, 7.4.1."
git push origin master
```

Wait for the preparation commit's CI checks to pass.

## Publish RubyGems and GitHub

```sh
bundle exec rake release
```

This builds the gem and pushes its tag and package. Complete RubyGems MFA when requested. If publication is interrupted, check which steps succeeded before retrying; never move an existing release tag. If the tag was pushed but the gem was not published, resume with `gem push pkg/mongoid-geospatial-7.4.1.gem`.

A tag alone is not a GitHub release. After verifying RubyGems publication, publish the matching GitHub release with that version's changelog entries:

```sh
version=7.4.1
notes="$(mktemp)"
awk -v version="$version" '
  /^## / {
    if (found) exit
    if ($2 == version) found = 1
    next
  }
  found { print }
' CHANGELOG.md > "$notes"
gh release create "v$version" --repo mongoid/mongoid-geospatial --verify-tag --title "$version" --notes-file "$notes" --latest
rm "$notes"
curl --fail --silent --show-error "https://rubygems.org/api/v2/rubygems/mongoid-geospatial/versions/$version.json"
gh release view "v$version" --repo mongoid/mongoid-geospatial
```

Both RubyGems publication and a non-draft GitHub release must be verified before the release is complete.

## Prepare the Next Version

Increment the development patch version (for example, `7.4.2`) in `lib/mongoid/geospatial/version.rb`. Add `## 7.4.2 (Next)` and a contribution placeholder above the released changelog section. Commit and push these changes to `master` without changing the released tag.
