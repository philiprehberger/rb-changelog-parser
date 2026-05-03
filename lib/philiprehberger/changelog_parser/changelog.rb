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

      # Return sorted unique category names present across all version entries
      #
      # @return [Array<String>] sorted unique category names
      def categories
        @entries.flat_map { |e| e.categories.keys }.uniq.sort
      end

      # Return the total count of line items across all versions and categories
      #
      # @return [Integer] total entry count
      def entry_count
        @entries.sum { |e| e.categories.values.sum(&:size) }
      end

      # Whether the changelog has no line-item entries (released or unreleased)
      #
      # @return [Boolean]
      def empty?
        entry_count.zero?
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

      # Returns combined entries for all versions between from_version (exclusive) and to_version (inclusive).
      #
      # @param from_version [String] starting version (exclusive)
      # @param to_version [String] ending version (inclusive)
      # @return [Hash<String, Array<String>>] merged categories with entries
      # @raise [Error] if either version is not found
      def diff(from_version, to_version)
        from_idx = @entries.index { |e| e.version == from_version }
        to_idx = @entries.index { |e| e.version == to_version }
        raise Philiprehberger::ChangelogParser::Error, "version not found: #{from_version}" unless from_idx
        raise Philiprehberger::ChangelogParser::Error, "version not found: #{to_version}" unless to_idx

        low, high = [from_idx, to_idx].sort
        range = @entries[low..high].reject { |e| e.version == from_version }
        merge_categories(range)
      end

      # Returns combined entries for all versions newer than the given version.
      #
      # @param version_string [String] version to start from (exclusive)
      # @return [Hash<String, Array<String>>] merged categories with entries
      # @raise [Error] if version is not found
      def since(version_string)
        idx = @entries.index { |e| e.version == version_string }
        raise Philiprehberger::ChangelogParser::Error, "version not found: #{version_string}" unless idx

        range = @entries[0...idx].reject { |e| e.version == 'Unreleased' }
        merge_categories(range)
      end

      # Search all entries for a keyword or pattern.
      #
      # @param query [String, Regexp] the search term
      # @return [Array<Hash>] matches with :version, :category, and :entry keys
      def search(query)
        pattern = query.is_a?(Regexp) ? query : /#{Regexp.escape(query)}/i
        matches = []

        @entries.each do |entry|
          entry.categories.each do |category, items|
            items.each do |item|
              matches << { version: entry.version, category: category, entry: item } if pattern.match?(item)
            end
          end
        end

        matches
      end

      # Validate the changelog for common issues.
      #
      # @return [Array<String>] warning messages (empty if valid)
      def validate
        warnings = []
        released = @entries.reject { |e| e.version == 'Unreleased' }

        # Check for duplicate versions
        version_names = released.map(&:version)
        duplicates = version_names.select { |v| version_names.count(v) > 1 }.uniq
        warnings.concat(duplicates.map { |v| "duplicate version: #{v}" })

        # Check dates are in descending order
        dates = released.filter_map(&:date)
        dates.each_cons(2) do |newer, older|
          warnings << "date out of order: #{newer} before #{older}" if newer < older
        end

        # Check for empty released versions
        released.each do |entry|
          warnings << "empty version: #{entry.version}" if entry.empty?
        end

        warnings
      end

      # Write the changelog to a file
      #
      # @param path [String] the file path
      # @return [void]
      def write(path)
        File.write(path, to_markdown)
      end

      # Return all entries from a specific category across all versions.
      #
      # @param category [String] the category to filter by (e.g., 'Added', 'Fixed')
      # @return [Array<Hash>] matches with :version, :date, and :entry keys
      def filter(category:)
        results = []

        @entries.each do |entry|
          next unless entry.categories.key?(category)

          entry.categories[category].each do |item|
            results << { version: entry.version, date: entry.date, entry: item }
          end
        end

        results
      end

      # Remove an entry from a version under a category
      #
      # @param version_string [String] the version to remove from
      # @param category [String] the category
      # @param entry [String] the entry text to remove
      # @return [void]
      # @raise [Error] if the version or entry is not found
      def remove(version_string, category, entry)
        ver = version(version_string)
        raise Error, "version #{version_string} not found" unless ver
        raise Error, "entry not found in #{version_string} [#{category}]" unless ver.categories[category]&.include?(entry)

        ver.categories[category].delete(entry)
        ver.categories.delete(category) if ver.categories[category].empty?
      end

      # Deserialize a changelog from a JSON string
      #
      # @param json_string [String] JSON produced by #to_json
      # @return [Changelog] the deserialized changelog
      def self.from_json(json_string)
        require 'json'
        data = JSON.parse(json_string)

        entries = data['versions'].map do |v|
          categories = v['categories'].transform_values(&:dup)
          VersionEntry.new(version: v['version'], date: v['date'], categories: categories)
        end

        new(title: data['title'], preamble: '', entries: entries)
      end

      # Serialize the changelog as a JSON string
      #
      # @param args [Array] arguments forwarded to Hash#to_json
      # @return [String] the JSON string
      def to_json(*args)
        require 'json'
        {
          title: @title,
          versions: @entries.map do |entry|
            {
              version: entry.version,
              date: entry.date,
              categories: entry.categories
            }
          end
        }.to_json(*args)
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

      private

      def merge_categories(entries)
        result = {}
        entries.each do |entry|
          entry.categories.each do |category, items|
            result[category] ||= []
            result[category].concat(items)
          end
        end
        result
      end
    end
  end
end
