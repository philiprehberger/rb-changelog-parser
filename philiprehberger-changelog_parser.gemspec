# frozen_string_literal: true

require_relative 'lib/philiprehberger/changelog_parser/version'

Gem::Specification.new do |spec|
  spec.name          = 'philiprehberger-changelog_parser'
  spec.version       = Philiprehberger::ChangelogParser::VERSION
  spec.authors       = ['Philip Rehberger']
  spec.email         = ['me@philiprehberger.com']

  spec.summary       = 'Parser for Keep a Changelog format with querying and write-back'
  spec.description   = 'Parse Keep a Changelog formatted markdown files with version querying, category management, ' \
                       'release creation, and markdown write-back support.'
  spec.homepage      = 'https://github.com/philiprehberger/rb-changelog-parser'
  spec.license       = 'MIT'

  spec.required_ruby_version = '>= 3.1.0'

  spec.metadata['homepage_uri']          = spec.homepage
  spec.metadata['source_code_uri']       = spec.homepage
  spec.metadata['changelog_uri']         = "#{spec.homepage}/blob/main/CHANGELOG.md"
  spec.metadata['bug_tracker_uri']       = "#{spec.homepage}/issues"
  spec.metadata['rubygems_mfa_required'] = 'true'

  spec.files = Dir['lib/**/*.rb', 'LICENSE', 'README.md', 'CHANGELOG.md']
  spec.require_paths = ['lib']
end
