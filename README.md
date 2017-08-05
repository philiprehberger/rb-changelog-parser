# philiprehberger-changelog_parser

[![Tests](https://github.com/philiprehberger/rb-changelog-parser/actions/workflows/ci.yml/badge.svg)](https://github.com/philiprehberger/rb-changelog-parser/actions/workflows/ci.yml)
[![Gem Version](https://badge.fury.io/rb/philiprehberger-changelog_parser.svg)](https://rubygems.org/gems/philiprehberger-changelog_parser)
[![License](https://img.shields.io/github/license/philiprehberger/rb-changelog-parser)](LICENSE)
[![Sponsor](https://img.shields.io/badge/sponsor-GitHub%20Sponsors-ec6cb9)](https://github.com/sponsors/philiprehberger)

Parser for Keep a Changelog format with querying and write-back

## Requirements

- Ruby >= 3.1

## Installation

Add to your Gemfile:

```ruby
gem "philiprehberger-changelog_parser"
```

Or install directly:

```bash
gem install philiprehberger-changelog_parser
```

## Usage

```ruby
require "philiprehberger/changelog_parser"

changelog = Philiprehberger::ChangelogParser.parse('CHANGELOG.md')
changelog.versions   # => ['Unreleased', '0.2.0', '0.1.0']
changelog.latest     # => VersionEntry for 0.2.0
```

### Querying Versions

```ruby
entry = changelog.version('0.2.0')
entry.date                  # => '2026-03-20'
entry.categories['Added']   # => ['New feature A', 'New feature B']
```

### Adding Entries

```ruby
changelog.add('Unreleased', 'Added', 'New search feature')
changelog.add('Unreleased', 'Fixed', 'Resolved login bug')
```

### Releasing a Version

```ruby
changelog.release('0.3.0', date: '2026-03-22')
# Moves Unreleased entries to the new version
```

### Writing Back

```ruby
changelog.write('CHANGELOG.md')
# Or get the markdown string
markdown = changelog.to_markdown
```

### Parsing Strings

```ruby
changelog = Philiprehberger::ChangelogParser.parse(<<~MD)
  # Changelog

  ## [Unreleased]

  ## [0.1.0] - 2026-03-15

  ### Added
  - Initial release
MD
```

## API

### `ChangelogParser`

| Method | Description |
|--------|-------------|
| `.parse(path_or_string)` | Parse a changelog from a file path or string |

### `Changelog`

| Method | Description |
|--------|-------------|
| `#versions` | Return all version strings |
| `#version(v)` | Find a specific version entry |
| `#unreleased` | Return the Unreleased entry |
| `#latest` | Return the latest released version |
| `#add(version, category, entry)` | Add an entry to a version |
| `#release(version, date:)` | Create a release from Unreleased |
| `#write(path)` | Write changelog to a file |
| `#to_markdown` | Render as markdown string |

### `VersionEntry`

| Method | Description |
|--------|-------------|
| `#version` | The version string |
| `#date` | The release date |
| `#categories` | Hash of category to entries |

## Development

```bash
bundle install
bundle exec rspec
bundle exec rubocop
```

## License

MIT
