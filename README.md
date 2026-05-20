# philiprehberger-changelog_parser

[![Tests](https://github.com/philiprehberger/rb-changelog-parser/actions/workflows/ci.yml/badge.svg)](https://github.com/philiprehberger/rb-changelog-parser/actions/workflows/ci.yml)
[![Gem Version](https://badge.fury.io/rb/philiprehberger-changelog_parser.svg)](https://rubygems.org/gems/philiprehberger-changelog_parser)
[![Last updated](https://img.shields.io/github/last-commit/philiprehberger/rb-changelog-parser)](https://github.com/philiprehberger/rb-changelog-parser/commits/main)

![philiprehberger-changelog_parser](https://raw.githubusercontent.com/philiprehberger/rb-changelog-parser/main/package-card.webp)

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

changelog.empty?            # => false (true for templates and freshly-initialized changelogs)
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

### JSON Serialization

```ruby
json = changelog.to_json
# => '{"title":"Changelog","versions":[{"version":"Unreleased","date":null,"categories":{}},...]}'
```

### Comparing Versions

```ruby
require "philiprehberger/changelog_parser"

changelog = Philiprehberger::ChangelogParser.parse("CHANGELOG.md")

# Get all changes between two versions
changes = changelog.diff("0.1.0", "0.3.0")
changes["Added"]  # => ["Feature B", "Feature C"]

# Get all changes since a version (merged categories)
recent = changelog.since("0.1.0")
recent["Fixed"]   # => ["Bug fix B"]

# Get per-version entries newer than a version (newest first)
entries = changelog.entries_since("0.1.0")
entries.map(&:version)  # => ["0.3.0", "0.2.0"]
```

### Searching Entries

```ruby
results = changelog.search("authentication")
results.each do |match|
  puts "#{match[:version]} [#{match[:category]}] #{match[:entry]}"
end

# Also accepts regex
changelog.search(/\bbug\b/i)
```

### Validation

```ruby
warnings = changelog.validate
# => ["empty version: 0.2.0", "date out of order: 2026-03-01 before 2026-03-15"]
```

### Filtering by Category

```ruby
added = changelog.filter(category: 'Added')
added.each do |match|
  puts "#{match[:version]} (#{match[:date]}): #{match[:entry]}"
end
```

### Removing Entries

```ruby
changelog.remove('Unreleased', 'Added', 'Obsolete feature')
```

### JSON Round-Trip

```ruby
json = changelog.to_json
restored = Philiprehberger::ChangelogParser.from_json(json)
restored.versions  # => same as original
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
| `.from_json(json_string)` | Deserialize a changelog from a JSON string |

### `Changelog`

| Method | Description |
|--------|-------------|
| `#versions` | Return all version strings |
| `#version(v)` | Find a specific version entry |
| `#categories` | Sorted unique category names across all entries |
| `#entry_count` | Total count of line items across all versions |
| `#empty?` | True when the changelog has no line-item entries |
| `#unreleased` | Return the Unreleased entry |
| `#latest` | Return the latest released version |
| `#add(version, category, entry)` | Add an entry to a version |
| `#remove(version, category, entry)` | Remove an entry from a version |
| `#release(version, date:)` | Create a release from Unreleased |
| `#write(path)` | Write changelog to a file |
| `#diff(from, to)` | Returns merged entries between two versions |
| `#since(version)` | Returns merged entries newer than a version |
| `#entries_since(version, include_unreleased: false)` | Returns per-version `VersionEntry` records newer than a version (newest first) |
| `#filter(category:)` | Return all entries from a specific category across versions |
| `#search(query)` | Search entries by keyword or regex |
| `#validate` | Check for common issues (duplicates, date order, empty versions) |
| `#to_json` | Serialize as JSON string |
| `#to_markdown` | Render as markdown string |

### `VersionEntry`

| Method | Description |
|--------|-------------|
| `#version` | The version string |
| `#date` | The release date |
| `#categories` | Hash of category to entries |
| `#empty?` | True if version has no entries |

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
