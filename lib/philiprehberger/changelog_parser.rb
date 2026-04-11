# frozen_string_literal: true

require_relative 'changelog_parser/version'
require_relative 'changelog_parser/parser'

module Philiprehberger
  module ChangelogParser
    class Error < StandardError; end

    # Parse a changelog from a file path or string
    #
    # @param input [String] file path or markdown string
    # @return [Changelog] the parsed changelog
    def self.parse(input)
      Parser.call(input)
    end

    # Deserialize a changelog from a JSON string
    #
    # @param json_string [String] JSON produced by Changelog#to_json
    # @return [Changelog] the deserialized changelog
    def self.from_json(json_string)
      Changelog.from_json(json_string)
    end
  end
end
