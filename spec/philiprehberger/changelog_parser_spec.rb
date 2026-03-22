# frozen_string_literal: true

require 'spec_helper'
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

    describe '#write' do
      it 'writes the changelog to a file' do
        tmpfile = File.join(Dir.tmpdir, 'test_changelog.md')
        changelog.write(tmpfile)
        content = File.read(tmpfile)
        expect(content).to include('# Changelog')
        expect(content).to include('## [0.2.0] - 2026-03-20')
      ensure
        File.delete(tmpfile) if File.exist?(tmpfile)
      end

      it 'writes a file that can be re-parsed' do
        tmpfile = File.join(Dir.tmpdir, 'test_roundtrip_changelog.md')
        changelog.write(tmpfile)
        reparsed = Philiprehberger::ChangelogParser.parse(tmpfile)
        expect(reparsed.versions).to eq(['Unreleased', '0.2.0', '0.1.0'])
      ensure
        File.delete(tmpfile) if File.exist?(tmpfile)
      end
    end
  end

  describe Philiprehberger::ChangelogParser::VersionEntry do
    describe '#add_entry' do
      it 'creates a new category array if needed' do
        entry = described_class.new(version: '1.0.0')
        entry.add_entry('Added', 'Feature')
        expect(entry.categories['Added']).to eq(['Feature'])
      end

      it 'appends to existing category' do
        entry = described_class.new(version: '1.0.0', categories: { 'Added' => ['First'] })
        entry.add_entry('Added', 'Second')
        expect(entry.categories['Added']).to eq(['First', 'Second'])
      end
    end
  end
end
