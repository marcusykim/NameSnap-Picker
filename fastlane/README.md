fastlane documentation
----

# Installation

Make sure you have the latest version of the Xcode command line tools installed:

```sh
xcode-select --install
```

For _fastlane_ installation instructions, see [Installing _fastlane_](https://docs.fastlane.tools/#installing-fastlane)

# Available Actions

## iOS

### ios upload_build

```sh
[bundle exec] fastlane ios upload_build
```

Upload the signed NameSnap build to App Store Connect

### ios upload_listing

```sh
[bundle exec] fastlane ios upload_listing
```

Upload production listing metadata and final screenshots

### ios submit_production

```sh
[bundle exec] fastlane ios submit_production
```

Select build 11 and submit NameSnap 2.0 for full App Store review

----

This README.md is auto-generated and will be re-generated every time [_fastlane_](https://fastlane.tools) is run.

More information about _fastlane_ can be found on [fastlane.tools](https://fastlane.tools).

The documentation of _fastlane_ can be found on [docs.fastlane.tools](https://docs.fastlane.tools).
