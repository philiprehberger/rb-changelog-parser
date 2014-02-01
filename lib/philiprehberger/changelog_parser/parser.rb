# frozen_string_literal: true

require_relative 'changelog'
require_relative 'version_entry'

module Philiprehberger
  module ChangelogParser
    # Parses Keep a Changelog formatted markdown
    class Parser
      VERSION_HEADER = /^##\s+\[(.+?)\](?:\s+-\s+(.+))?$/
      CATEGORY_HEADER = /^###\s+(.+)$/
      LIST_ITEM = /^-\s+(.+)$/
      TITLE_HEADER = /^#\s+(.+)$/

      # Parse a changelog from a file path or string
      #
      # @param input [String] file path or markdown string
      # @return [Changelog] the parsed changelog
      def self.call(input)
        content = File.exist?(input) ? File.read(input) : input
        new.parse(content)
      end

      # Parse changelog content
      #
      # @param content [String] the markdown content
      # @return [Changelog] the parsed changelog
      def parse(content)
        lines = content.lines.map(&:chomp)
        title = ''
        preamble_lines = []
        entries = []
        current_entry = nil
        current_category = nil
        in_preamble = true

        lines.each do |line|
          case line
          when TITLE_HEADER
            title = Regexp.last_match(1)
          when VERSION_HEADER
            in_preamble = false
            current_entry = VersionEntry.new(
              version: Regexp.last_match(1),
              date: Regexp.last_match(2)
            )
            entries << current_entry
            current_category = nil
          when CATEGORY_HEADER
            current_category = Regexp.last_match(1) if current_entry
          when LIST_ITEM
            if current_entry && current_category
              current_entry.add_entry(current_category, Regexp.last_match(1))
            end
          else
            preamble_lines << line if in_preamble && !line.match?(TITLE_HEADER)
          end
        end

        preamble = preamble_lines.join("\n").strip
        preamble += "\n" unless preamble.empty?

        Changelog.new(title: title, preamble: preamble, entries: entries)
      end
    end
  end
end
