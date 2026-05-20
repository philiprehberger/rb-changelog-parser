# Changelog

All notable changes to this gem will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [0.8.0] - 2026-05-20

### Added
- `Changelog#entries_since(version, include_unreleased: false)` — returns per-version `VersionEntry` records newer than the given version (newest first), preserving release structure unlike the existing `#since` which flattens categories
- Card image reference in the README for registry-side rendering

## [0.7.0] - 2026-05-02

### Added
- `Changelog#empty?` — true when the changelog has no line-item entries (released or unreleased), useful for templates and freshly-initialized changelogs

## [0.6.0] - 2026-04-22

### Added
- `Changelog#categories` — return a sorted array of unique category names across all version entries.
- `Changelog#entry_count` — return the total number of line items across all versions and categories.

## [0.5.0] - 2026-04-10

### Added
- `Changelog.from_json(json_string)` for JSON deserialization and round-trip support
- `Changelog#filter(category:)` to query entries by category across all versions
- `Changelog#remove(version, category, entry)` to remove entries from a version

## [0.4.0] - 2026-04-09

### Added
- `Changelog#search(query)` for keyword and regex search across all entries
- `Changelog#validate` to detect duplicate versions, dates out of order, and empty released versions
- `VersionEntry#empty?` convenience method

## [0.3.0] - 2026-04-04

### Added
- `to_json` method on `Changelog` for JSON serialization

## [0.2.0] - 2026-04-04

### Added
- `diff(from, to)` method for comparing changes between versions
- `since(version)` method for querying changes newer than a version
- GitHub issue template gem version field
- Feature request "Alternatives considered" field

## [0.1.5] - 2026-03-31

### Added
- Add GitHub issue templates, dependabot config, and PR template

## [0.1.4] - 2026-03-31

### Changed
- Standardize README badges, support section, and license format

## [0.1.3] - 2026-03-24

### Fixed
- Standardize README code examples to use double-quote require statements

## [0.1.2] - 2026-03-24

### Fixed
- Fix Installation section quote style to double quotes

## [0.1.1] - 2026-03-22

### Changed
- Expand test coverage

## [0.1.0] - 2026-03-22

### Added
- Initial release
- Parse Keep a Changelog formatted markdown from file or string
- Query versions, unreleased, and latest entries
- Add entries to specific versions under categories
- Release unreleased changes with version and date
- Write-back to file and markdown rendering
