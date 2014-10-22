# Change Log

## Unreleased

### Added

- Mock for testing client integrations.
- Server configuration using command line arguments.

### Fixed

- Interaction with other gems that use a conflicting `#publish` method name
  (like Wisper) by having a `#sinapse_publish` method. The method is still
  aliased as `#publish` so you may want to include Sinapse before or after the
  conflicting gem (to use the gem's or sinapse's).


## v0.1.0 - 2014-05-20

Initial release.
