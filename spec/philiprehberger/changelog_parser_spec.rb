# frozen_string_literal: true

require 'spec_helper'
require 'json'
require 'tmpdir'

RSpec.describe Philiprehberger::ChangelogParser do
  let(:sample_changelog) do
    <<~MARKDOWN
      # Changelog

      All notable changes to this gem will be documented in this file.

      ## [Unreleased]

      ## [0.2.0] - 2026-03-20

      ### Added
      - New feature A
      - New feature B

      ### Fixed
      - Bug fix C

      ## [0.1.0] - 2026-03-15

      ### Added
      - Initial release
    MARKDOWN
  end

  it 'has a version number' do
    expect(described_class::VERSION).not_to be_nil
  end

  describe '.parse' do
    it 'parses a changelog string' do
      changelog = described_class.parse(sample_changelog)
      expect(changelog).to be_a(described_class::Changelog)
    end

    it 'parses an empty changelog' do
      changelog = described_class.parse('')
      expect(changelog.versions).to be_empty
      expect(changelog.title).to eq('')
    end

    it 'parses a changelog with only a title' do
      changelog = described_class.parse("# Changelog\n")
      expect(changelog.title).to eq('Changelog')
      expect(changelog.versions).to be_empty
    end

    it 'parses a changelog with only an Unreleased section' do
      content = <<~MARKDOWN
        # Changelog

        ## [Unreleased]

        ### Added
        - Something pending
      MARKDOWN
      changelog = described_class.parse(content)
      expect(changelog.versions).to eq(['Unreleased'])
      expect(changelog.unreleased.categories['Added']).to eq(['Something pending'])
    end

    it 'parses a version with all six change types' do
      content = <<~MARKDOWN
        # Changelog

        ## [1.0.0] - 2026-01-01

        ### Added
        - New feature

        ### Changed
        - Updated behavior

        ### Deprecated
        - Old API

        ### Removed
        - Legacy code

        ### Fixed
        - Bug squashed

        ### Security
        - Patched vulnerability
      MARKDOWN
      changelog = described_class.parse(content)
      entry = changelog.version('1.0.0')
      expect(entry.categories.keys).to contain_exactly(
        'Added', 'Changed', 'Deprecated', 'Removed', 'Fixed', 'Security'
      )
      expect(entry.categories['Security']).to eq(['Patched vulnerability'])
    end

    it 'parses entries with markdown formatting' do
      content = <<~MARKDOWN
        # Changelog

        ## [0.1.0] - 2026-01-01

        ### Added
        - Support for `backtick` formatting
        - Added **bold** text in entry
        - Link to [example](https://example.com)
      MARKDOWN
      changelog = described_class.parse(content)
      entries = changelog.version('0.1.0').categories['Added']
      expect(entries).to include('Support for `backtick` formatting')
      expect(entries).to include('Added **bold** text in entry')
      expect(entries).to include('Link to [example](https://example.com)')
    end

    it 'parses multiple versions in correct order' do
      content = <<~MARKDOWN
        # Changelog

        ## [Unreleased]

        ## [3.0.0] - 2026-03-01

        ### Added
        - V3

        ## [2.0.0] - 2026-02-01

        ### Added
        - V2

        ## [1.0.0] - 2026-01-01

        ### Added
        - V1
      MARKDOWN
      changelog = described_class.parse(content)
      expect(changelog.versions).to eq(['Unreleased', '3.0.0', '2.0.0', '1.0.0'])
    end

    it 'preserves preamble text' do
      content = <<~MARKDOWN
        # Changelog

        All notable changes will be documented here.

        ## [0.1.0] - 2026-01-01

        ### Added
        - First
      MARKDOWN
      changelog = described_class.parse(content)
      expect(changelog.preamble).to include('All notable changes')
    end

    it 'handles version without date' do
      content = <<~MARKDOWN
        # Changelog

        ## [Unreleased]

        ### Added
        - Pending work
      MARKDOWN
      changelog = described_class.parse(content)
      expect(changelog.unreleased.date).to be_nil
    end

    it 'handles version with empty categories' do
      content = <<~MARKDOWN
        # Changelog

        ## [0.1.0] - 2026-01-01
      MARKDOWN
      changelog = described_class.parse(content)
      entry = changelog.version('0.1.0')
      expect(entry.categories).to be_empty
    end

    it 'ignores list items before any version header' do
      content = <<~MARKDOWN
        # Changelog

        - This is not in any version

        ## [0.1.0] - 2026-01-01

        ### Added
        - Real entry
      MARKDOWN
      changelog = described_class.parse(content)
      entry = changelog.version('0.1.0')
      expect(entry.categories['Added']).to eq(['Real entry'])
    end

    it 'ignores list items without a category header' do
      content = <<~MARKDOWN
        # Changelog

        ## [0.1.0] - 2026-01-01

        - Orphan entry without category
      MARKDOWN
      changelog = described_class.parse(content)
      entry = changelog.version('0.1.0')
      expect(entry.categories).to be_empty
    end
  end

  describe Philiprehberger::ChangelogParser::Changelog do
    subject(:changelog) { Philiprehberger::ChangelogParser.parse(sample_changelog) }

    describe '#versions' do
      it 'returns all version strings' do
        expect(changelog.versions).to eq(['Unreleased', '0.2.0', '0.1.0'])
      end
    end

    describe '#version' do
      it 'finds a specific version' do
        entry = changelog.version('0.2.0')
        expect(entry).not_to be_nil
        expect(entry.version).to eq('0.2.0')
        expect(entry.date).to eq('2026-03-20')
      end

      it 'returns nil for missing versions' do
        expect(changelog.version('9.9.9')).to be_nil
      end

      it 'finds the earliest version' do
        entry = changelog.version('0.1.0')
        expect(entry).not_to be_nil
        expect(entry.date).to eq('2026-03-15')
      end
    end

    describe '#categories' do
      it 'returns sorted unique category names across all versions' do
        expect(changelog.categories).to eq(%w[Added Fixed])
      end

      it 'returns an empty array when there are no categories' do
        content = <<~MARKDOWN
          # Changelog

          ## [0.1.0] - 2026-01-01
        MARKDOWN
        cl = Philiprehberger::ChangelogParser.parse(content)
        expect(cl.categories).to eq([])
      end

      it 'dedupes category names across multiple versions' do
        content = <<~MARKDOWN
          # Changelog

          ## [0.2.0] - 2026-02-01

          ### Added
          - Feature B

          ### Security
          - Patched CVE

          ## [0.1.0] - 2026-01-01

          ### Added
          - Feature A

          ### Changed
          - Behavior tweak
        MARKDOWN
        cl = Philiprehberger::ChangelogParser.parse(content)
        expect(cl.categories).to eq(%w[Added Changed Security])
      end
    end

    describe '#entry_count' do
      it 'counts all entries across all versions and categories' do
        expect(changelog.entry_count).to eq(4)
      end

      it 'returns 0 for a changelog with no entries' do
        content = <<~MARKDOWN
          # Changelog

          ## [0.1.0] - 2026-01-01
        MARKDOWN
        cl = Philiprehberger::ChangelogParser.parse(content)
        expect(cl.entry_count).to eq(0)
      end

      it 'sums entries across multiple versions and categories' do
        content = <<~MARKDOWN
          # Changelog

          ## [0.2.0] - 2026-02-01

          ### Added
          - Feature B1
          - Feature B2

          ### Fixed
          - Bug B

          ## [0.1.0] - 2026-01-01

          ### Added
          - Feature A
        MARKDOWN
        cl = Philiprehberger::ChangelogParser.parse(content)
        expect(cl.entry_count).to eq(4)
      end
    end

    describe '#unreleased' do
      it 'returns the Unreleased entry' do
        entry = changelog.unreleased
        expect(entry).not_to be_nil
        expect(entry.version).to eq('Unreleased')
      end

      it 'returns nil when no Unreleased section exists' do
        content = <<~MARKDOWN
          # Changelog

          ## [0.1.0] - 2026-01-01

          ### Added
          - Something
        MARKDOWN
        cl = Philiprehberger::ChangelogParser.parse(content)
        expect(cl.unreleased).to be_nil
      end
    end

    describe '#latest' do
      it 'returns the latest released version' do
        entry = changelog.latest
        expect(entry.version).to eq('0.2.0')
      end

      it 'returns nil when only Unreleased exists' do
        content = <<~MARKDOWN
          # Changelog

          ## [Unreleased]

          ### Added
          - Something
        MARKDOWN
        cl = Philiprehberger::ChangelogParser.parse(content)
        expect(cl.latest).to be_nil
      end
    end

    describe '#add' do
      it 'adds an entry to a version' do
        changelog.add('Unreleased', 'Added', 'New feature')
        entry = changelog.unreleased
        expect(entry.categories['Added']).to include('New feature')
      end

      it 'raises for missing versions' do
        expect { changelog.add('9.9.9', 'Added', 'test') }.to raise_error(Philiprehberger::ChangelogParser::Error)
      end

      it 'creates a new category when adding to a version' do
        changelog.add('0.2.0', 'Security', 'Patched XSS')
        entry = changelog.version('0.2.0')
        expect(entry.categories['Security']).to eq(['Patched XSS'])
      end

      it 'appends multiple entries to the same category' do
        changelog.add('Unreleased', 'Added', 'Feature X')
        changelog.add('Unreleased', 'Added', 'Feature Y')
        entries = changelog.unreleased.categories['Added']
        expect(entries).to eq(['Feature X', 'Feature Y'])
      end
    end

    describe '#release' do
      it 'creates a new version from Unreleased' do
        changelog.add('Unreleased', 'Added', 'Something new')
        new_entry = changelog.release('0.3.0', date: '2026-03-22')
        expect(new_entry.version).to eq('0.3.0')
        expect(new_entry.date).to eq('2026-03-22')
        expect(new_entry.categories['Added']).to include('Something new')
        expect(changelog.unreleased.categories).to be_empty
      end

      it 'raises when no Unreleased section exists' do
        content = <<~MARKDOWN
          # Changelog

          ## [0.1.0] - 2026-01-01

          ### Added
          - Something
        MARKDOWN
        cl = Philiprehberger::ChangelogParser.parse(content)
        expect { cl.release('0.2.0', date: '2026-03-22') }.to raise_error(
          Philiprehberger::ChangelogParser::Error, 'no Unreleased section found'
        )
      end

      it 'inserts the released version right after Unreleased' do
        changelog.add('Unreleased', 'Fixed', 'A bug')
        changelog.release('0.3.0', date: '2026-03-22')
        expect(changelog.versions).to eq(['Unreleased', '0.3.0', '0.2.0', '0.1.0'])
      end
    end

    describe '#to_markdown' do
      it 'renders the changelog as markdown' do
        markdown = changelog.to_markdown
        expect(markdown).to include('# Changelog')
        expect(markdown).to include('## [0.2.0] - 2026-03-20')
        expect(markdown).to include('- New feature A')
      end

      it 'renders Unreleased without a date' do
        markdown = changelog.to_markdown
        expect(markdown).to include('## [Unreleased]')
        expect(markdown).not_to include('## [Unreleased] -')
      end

      it 'roundtrips through parse and to_markdown' do
        markdown1 = changelog.to_markdown
        reparsed = Philiprehberger::ChangelogParser.parse(markdown1)
        expect(reparsed.versions).to eq(changelog.versions)
        expect(reparsed.version('0.2.0').categories['Added']).to eq(['New feature A', 'New feature B'])
      end
    end

    describe '#to_json' do
      it 'serializes the changelog as a JSON string' do
        json = changelog.to_json
        parsed = JSON.parse(json)
        expect(parsed['title']).to eq('Changelog')
        expect(parsed['versions'].length).to eq(3)
      end

      it 'includes version, date, and categories for each entry' do
        parsed = JSON.parse(changelog.to_json)
        entry = parsed['versions'].find { |v| v['version'] == '0.2.0' }
        expect(entry['date']).to eq('2026-03-20')
        expect(entry['categories']['Added']).to eq(['New feature A', 'New feature B'])
        expect(entry['categories']['Fixed']).to eq(['Bug fix C'])
      end

      it 'sets date to nil for Unreleased' do
        parsed = JSON.parse(changelog.to_json)
        unreleased = parsed['versions'].find { |v| v['version'] == 'Unreleased' }
        expect(unreleased['date']).to be_nil
      end

      it 'returns empty categories for versions with no entries' do
        content = <<~MARKDOWN
          # Changelog

          ## [0.1.0] - 2026-01-01
        MARKDOWN
        cl = Philiprehberger::ChangelogParser.parse(content)
        parsed = JSON.parse(cl.to_json)
        expect(parsed['versions'].first['categories']).to eq({})
      end
    end

    describe '#write' do
      it 'writes the changelog to a file' do
        tmpfile = File.join(Dir.tmpdir, 'test_changelog.md')
        changelog.write(tmpfile)
        content = File.read(tmpfile)
        expect(content).to include('# Changelog')
        expect(content).to include('## [0.2.0] - 2026-03-20')
      ensure
        FileUtils.rm_f(tmpfile)
      end

      it 'writes a file that can be re-parsed' do
        tmpfile = File.join(Dir.tmpdir, 'test_roundtrip_changelog.md')
        changelog.write(tmpfile)
        reparsed = Philiprehberger::ChangelogParser.parse(tmpfile)
        expect(reparsed.versions).to eq(['Unreleased', '0.2.0', '0.1.0'])
      ensure
        FileUtils.rm_f(tmpfile)
      end
    end
  end

  describe '#diff' do
    let(:changelog_text) do
      <<~MD
        # Changelog

        ## [Unreleased]

        ## [0.3.0] - 2026-04-01

        ### Added
        - Feature C

        ## [0.2.0] - 2026-03-15

        ### Added
        - Feature B

        ### Fixed
        - Bug fix B

        ## [0.1.0] - 2026-03-01

        ### Added
        - Feature A
      MD
    end
    let(:changelog) { Philiprehberger::ChangelogParser.parse(changelog_text) }

    it 'returns entries between two versions' do
      result = changelog.diff('0.1.0', '0.3.0')
      expect(result['Added']).to contain_exactly('Feature B', 'Feature C')
    end

    it 'includes the to_version entries' do
      result = changelog.diff('0.1.0', '0.2.0')
      expect(result['Added']).to eq(['Feature B'])
      expect(result['Fixed']).to eq(['Bug fix B'])
    end

    it 'excludes the from_version entries' do
      result = changelog.diff('0.1.0', '0.2.0')
      expect(result['Added']).not_to include('Feature A')
    end

    it 'raises for unknown from_version' do
      expect { changelog.diff('9.9.9', '0.2.0') }.to raise_error(Philiprehberger::ChangelogParser::Error)
    end

    it 'raises for unknown to_version' do
      expect { changelog.diff('0.1.0', '9.9.9') }.to raise_error(Philiprehberger::ChangelogParser::Error)
    end

    it 'returns empty hash for same version' do
      result = changelog.diff('0.2.0', '0.2.0')
      expect(result).to eq({})
    end
  end

  describe '#since' do
    let(:changelog_text) do
      <<~MD
        # Changelog

        ## [Unreleased]

        ## [0.3.0] - 2026-04-01

        ### Added
        - Feature C

        ## [0.2.0] - 2026-03-15

        ### Added
        - Feature B

        ## [0.1.0] - 2026-03-01

        ### Added
        - Feature A
      MD
    end
    let(:changelog) { Philiprehberger::ChangelogParser.parse(changelog_text) }

    it 'returns all entries since a version' do
      result = changelog.since('0.1.0')
      expect(result['Added']).to contain_exactly('Feature C', 'Feature B')
    end

    it 'excludes Unreleased entries' do
      result = changelog.since('0.1.0')
      expect(result.values.flatten).not_to be_empty
    end

    it 'returns empty when since latest' do
      result = changelog.since('0.3.0')
      expect(result).to eq({})
    end

    it 'raises for unknown version' do
      expect { changelog.since('9.9.9') }.to raise_error(Philiprehberger::ChangelogParser::Error)
    end
  end

  describe '#search' do
    let(:changelog_text) do
      <<~MD
        # Changelog

        ## [Unreleased]

        ### Added
        - Search API endpoint

        ## [0.2.0] - 2026-03-15

        ### Added
        - User authentication
        - Search widget

        ### Fixed
        - Login redirect bug

        ## [0.1.0] - 2026-03-01

        ### Added
        - Initial release
      MD
    end
    let(:changelog) { Philiprehberger::ChangelogParser.parse(changelog_text) }

    it 'finds entries matching a keyword' do
      results = changelog.search('search')
      expect(results.length).to eq(2)
      expect(results.map { |r| r[:entry] }).to contain_exactly('Search API endpoint', 'Search widget')
    end

    it 'is case-insensitive by default' do
      results = changelog.search('LOGIN')
      expect(results.length).to eq(1)
      expect(results.first[:entry]).to eq('Login redirect bug')
    end

    it 'returns version and category context' do
      results = changelog.search('authentication')
      expect(results.first[:version]).to eq('0.2.0')
      expect(results.first[:category]).to eq('Added')
    end

    it 'accepts a regex pattern' do
      results = changelog.search(/\bredirect\b/)
      expect(results.length).to eq(1)
    end

    it 'returns empty array for no matches' do
      expect(changelog.search('nonexistent')).to be_empty
    end
  end

  describe '#filter' do
    let(:changelog_text) do
      <<~MD
        # Changelog

        ## [Unreleased]

        ### Added
        - Pending feature

        ## [0.3.0] - 2026-04-01

        ### Added
        - Feature C

        ### Fixed
        - Bug fix C

        ## [0.2.0] - 2026-03-15

        ### Added
        - Feature B

        ## [0.1.0] - 2026-03-01

        ### Added
        - Feature A

        ### Fixed
        - Bug fix A
      MD
    end
    let(:changelog) { Philiprehberger::ChangelogParser.parse(changelog_text) }

    it 'returns all entries for a given category' do
      results = changelog.filter(category: 'Added')
      expect(results.length).to eq(4)
      expect(results.map { |r| r[:entry] }).to eq(['Pending feature', 'Feature C', 'Feature B', 'Feature A'])
    end

    it 'includes version and date context' do
      results = changelog.filter(category: 'Fixed')
      expect(results.first[:version]).to eq('0.3.0')
      expect(results.first[:date]).to eq('2026-04-01')
    end

    it 'returns empty array for non-existent category' do
      expect(changelog.filter(category: 'Security')).to be_empty
    end
  end

  describe '#remove' do
    let(:changelog) { Philiprehberger::ChangelogParser.parse(sample_changelog) }

    it 'removes an entry from a version' do
      changelog.remove('0.2.0', 'Added', 'New feature A')
      expect(changelog.version('0.2.0').categories['Added']).to eq(['New feature B'])
    end

    it 'cleans up empty category arrays' do
      changelog.remove('0.2.0', 'Fixed', 'Bug fix C')
      expect(changelog.version('0.2.0').categories).not_to have_key('Fixed')
    end

    it 'raises for missing version' do
      expect { changelog.remove('9.9.9', 'Added', 'test') }.to raise_error(Philiprehberger::ChangelogParser::Error)
    end

    it 'raises for missing entry' do
      expect { changelog.remove('0.2.0', 'Added', 'nonexistent') }.to raise_error(
        Philiprehberger::ChangelogParser::Error, 'entry not found in 0.2.0 [Added]'
      )
    end

    it 'raises for missing category' do
      expect { changelog.remove('0.2.0', 'Security', 'test') }.to raise_error(
        Philiprehberger::ChangelogParser::Error
      )
    end
  end

  describe '.from_json' do
    let(:changelog) { Philiprehberger::ChangelogParser.parse(sample_changelog) }

    it 'round-trips through to_json and from_json' do
      json = changelog.to_json
      restored = Philiprehberger::ChangelogParser.from_json(json)
      expect(restored.versions).to eq(changelog.versions)
      expect(restored.title).to eq('Changelog')
    end

    it 'preserves version entries and categories' do
      json = changelog.to_json
      restored = Philiprehberger::ChangelogParser.from_json(json)
      entry = restored.version('0.2.0')
      expect(entry.date).to eq('2026-03-20')
      expect(entry.categories['Added']).to eq(['New feature A', 'New feature B'])
      expect(entry.categories['Fixed']).to eq(['Bug fix C'])
    end

    it 'preserves nil date for Unreleased' do
      json = changelog.to_json
      restored = Philiprehberger::ChangelogParser.from_json(json)
      expect(restored.unreleased.date).to be_nil
    end

    it 'produces a changelog that can be serialized again' do
      json1 = changelog.to_json
      restored = Philiprehberger::ChangelogParser.from_json(json1)
      json2 = restored.to_json
      expect(JSON.parse(json2)).to eq(JSON.parse(json1))
    end
  end

  describe '#validate' do
    it 'returns empty array for a valid changelog' do
      changelog = Philiprehberger::ChangelogParser.parse(<<~MD)
        # Changelog

        ## [Unreleased]

        ## [0.2.0] - 2026-03-15

        ### Added
        - Feature

        ## [0.1.0] - 2026-03-01

        ### Added
        - Initial release
      MD
      expect(changelog.validate).to be_empty
    end

    it 'detects duplicate versions' do
      changelog = Philiprehberger::ChangelogParser.parse(<<~MD)
        # Changelog

        ## [0.1.0] - 2026-03-15

        ### Added
        - First

        ## [0.1.0] - 2026-03-01

        ### Added
        - Second
      MD
      warnings = changelog.validate
      expect(warnings).to include('duplicate version: 0.1.0')
    end

    it 'detects dates out of order' do
      changelog = Philiprehberger::ChangelogParser.parse(<<~MD)
        # Changelog

        ## [0.2.0] - 2026-03-01

        ### Added
        - Feature

        ## [0.1.0] - 2026-03-15

        ### Added
        - Initial release
      MD
      warnings = changelog.validate
      expect(warnings).to include('date out of order: 2026-03-01 before 2026-03-15')
    end

    it 'detects empty released versions' do
      changelog = Philiprehberger::ChangelogParser.parse(<<~MD)
        # Changelog

        ## [0.1.0] - 2026-03-01
      MD
      warnings = changelog.validate
      expect(warnings).to include('empty version: 0.1.0')
    end
  end

  describe Philiprehberger::ChangelogParser::VersionEntry do
    describe '#empty?' do
      it 'returns true for a version with no categories' do
        entry = described_class.new(version: '1.0.0')
        expect(entry.empty?).to be true
      end

      it 'returns false for a version with entries' do
        entry = described_class.new(version: '1.0.0', categories: { 'Added' => ['Feature'] })
        expect(entry.empty?).to be false
      end

      it 'returns true for a version with empty category arrays' do
        entry = described_class.new(version: '1.0.0', categories: { 'Added' => [] })
        expect(entry.empty?).to be true
      end
    end

    describe '#add_entry' do
      it 'creates a new category array if needed' do
        entry = described_class.new(version: '1.0.0')
        entry.add_entry('Added', 'Feature')
        expect(entry.categories['Added']).to eq(['Feature'])
      end

      it 'appends to existing category' do
        entry = described_class.new(version: '1.0.0', categories: { 'Added' => ['First'] })
        entry.add_entry('Added', 'Second')
        expect(entry.categories['Added']).to eq(%w[First Second])
      end
    end
  end
end
