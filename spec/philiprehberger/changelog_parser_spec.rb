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
    end

    describe '#unreleased' do
      it 'returns the Unreleased entry' do
        entry = changelog.unreleased
        expect(entry).not_to be_nil
        expect(entry.version).to eq('Unreleased')
      end
    end

    describe '#latest' do
      it 'returns the latest released version' do
        entry = changelog.latest
        expect(entry.version).to eq('0.2.0')
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
    end

    describe '#to_markdown' do
      it 'renders the changelog as markdown' do
        markdown = changelog.to_markdown
        expect(markdown).to include('# Changelog')
        expect(markdown).to include('## [0.2.0] - 2026-03-20')
        expect(markdown).to include('- New feature A')
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
    end
  end
end
