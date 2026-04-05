# philiprehberger-changelog_parser

[![Tests](https://github.com/philiprehberger/rb-changelog-parser/actions/workflows/ci.yml/badge.svg)](https://github.com/philiprehberger/rb-changelog-parser/actions/workflows/ci.yml)
[![Gem Version](https://badge.fury.io/rb/philiprehberger-changelog_parser.svg)](https://rubygems.org/gems/philiprehberger-changelog_parser)
[![Last updated](https://img.shields.io/github/last-commit/philiprehberger/rb-changelog-parser)](https://github.com/philiprehberger/rb-changelog-parser/commits/main)

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

### Comparing Versions

```ruby
require "philiprehberger/changelog_parser"

changelog = Philiprehberger::ChangelogParser.parse("CHANGELOG.md")

# Get all changes between two versions
changes = changelog.diff("0.1.0", "0.3.0")
changes["Added"]  # => ["Feature B", "Feature C"]

# Get all changes since a version
recent = changelog.since("0.1.0")
recent["Fixed"]   # => ["Bug fix B"]
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
| `#diff(from, to)` | Returns merged entries between two versions |
| `#since(version)` | Returns merged entries newer than a version |
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

## Support

If you find this project useful:

⭐ [Star the repo](https://github.com/philiprehberger/rb-changelog-parser)

🐛 [Report issues](https://github.com/philiprehberger/rb-changelog-parser/issues?q=is%3Aissue+is%3Aopen+label%3Abug)

💡 [Suggest features](https://github.com/philiprehberger/rb-changelog-parser/issues?q=is%3Aissue+is%3Aopen+label%3Aenhancement)

❤️ [Sponsor development](https://github.com/sponsors/philiprehberger)

🌐 [All Open Source Projects](https://philiprehberger.com/open-source-packages)

💻 [GitHub Profile](https://github.com/philiprehberger)

🔗 [LinkedIn Profile](https://www.linkedin.com/in/philiprehberger)

## License

[MIT](LICENSE)
