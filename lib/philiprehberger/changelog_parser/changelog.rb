# frozen_string_literal: true

module Philiprehberger
  module ChangelogParser
    # Represents a parsed changelog with version entries
    class Changelog
      # @param title [String] the changelog title
      # @param preamble [String] text before first version
      # @param entries [Array<VersionEntry>] parsed version entries
      def initialize(title:, preamble:, entries:)
        @title = title
        @preamble = preamble
        @entries = entries
      end

      # @return [String] the changelog title
      attr_reader :title

      # @return [String] the preamble text
      attr_reader :preamble

      # Return all version strings
      #
      # @return [Array<String>] version strings
      def versions
        @entries.map(&:version)
      end

      # Find a specific version entry
      #
      # @param version_string [String] the version to find
      # @return [VersionEntry, nil] the version entry or nil
      def version(version_string)
        @entries.find { |e| e.version == version_string }
      end

      # Return the unreleased entry
      #
      # @return [VersionEntry, nil] the unreleased entry or nil
      def unreleased
        @entries.find { |e| e.version == 'Unreleased' }
      end

      # Return the latest released version
      #
      # @return [VersionEntry, nil] the latest version or nil
      def latest
        @entries.reject { |e| e.version == 'Unreleased' }.first
      end

      # Add an entry to a version under a category
      #
      # @param version_string [String] the version to add to
      # @param category [String] the category (Added, Changed, Fixed, etc.)
      # @param entry [String] the entry text
      # @return [void]
      def add(version_string, category, entry)
        ver = version(version_string)
        raise Error, "version #{version_string} not found" unless ver

        ver.add_entry(category, entry)
      end

      # Create a new released version from Unreleased
      #
      # @param version_string [String] the version number
      # @param date [String] the release date (YYYY-MM-DD)
      # @return [VersionEntry] the new version entry
      def release(version_string, date:)
        unrel = unreleased
        raise Error, 'no Unreleased section found' unless unrel

        new_entry = VersionEntry.new(
          version: version_string,
          date: date,
          categories: unrel.categories.transform_values(&:dup)
        )

        unrel.categories.clear
        idx = @entries.index(unrel)
        @entries.insert(idx + 1, new_entry)
        new_entry
      end

      # Write the changelog to a file
      #
      # @param path [String] the file path
      # @return [void]
      def write(path)
        File.write(path, to_markdown)
      end

      # Render the changelog as markdown
      #
      # @return [String] the markdown string
      def to_markdown
        lines = []
        lines << "# #{@title}"
        lines << ''
        lines << @preamble unless @preamble.empty?

        @entries.each do |entry|
          lines << if entry.date
                     "## [#{entry.version}] - #{entry.date}"
                   else
                     "## [#{entry.version}]"
                   end
          lines << ''

          entry.categories.each do |category, items|
            lines << "### #{category}"
            lines << ''
            items.each { |item| lines << "- #{item}" }
            lines << ''
          end
        end

        lines.join("\n")
      end
    end
  end
end
