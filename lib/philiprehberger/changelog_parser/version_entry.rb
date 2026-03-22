# frozen_string_literal: true

module Philiprehberger
  module ChangelogParser
    # Represents a single version entry in a changelog
    class VersionEntry
      # @param version [String] the version string
      # @param date [String, nil] the release date
      # @param categories [Hash<String, Array<String>>] category to entries mapping
      def initialize(version:, date: nil, categories: {})
        @version = version
        @date = date
        @categories = categories
      end

      # @return [String] the version string
      attr_reader :version

      # @return [String, nil] the release date
      attr_reader :date

      # @return [Hash<String, Array<String>>] category to entries mapping
      attr_reader :categories

      # Add an entry under a category
      #
      # @param category [String] the category name
      # @param entry [String] the entry text
      # @return [void]
      def add_entry(category, entry)
        @categories[category] ||= []
        @categories[category] << entry
      end
    end
  end
end
