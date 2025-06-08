# frozen_string_literal: true

require_relative 'lib/activerecord-mcp/version'

Gem::Specification.new do |spec|
  spec.name = 'activerecord-mcp'
  spec.version = ActiveRecordMcp::VERSION
  spec.authors = ['dak2']
  # spec.email = ["your.email@example.com"]

  spec.summary = 'MCP server for ActiveRecord operations'
  spec.description = 'A Model Context Protocol server that provides natural language querying capabilities for ActiveRecord models'
  spec.homepage = 'https://github.com/yourusername/activerecord-mcp'
  spec.license = 'MIT'
  spec.required_ruby_version = Gem::Requirement.new('>= 3.3.0')

  spec.metadata['homepage_uri'] = spec.homepage
  spec.metadata['source_code_uri'] = spec.homepage
  spec.metadata['changelog_uri'] = "#{spec.homepage}/blob/main/CHANGELOG.md"

  spec.files = Dir.glob('{lib,exe}/**/*') + %w[LICENSE.txt README.md]
  spec.bindir = 'exe'
  spec.executables = ['activerecord-mcp']
  spec.require_paths = ['lib']

  spec.add_dependency 'activerecord', '>= 8.0'
  spec.add_dependency 'activesupport', '>= 8.0'
  spec.add_dependency 'mcp'

  # Development dependencies
  spec.add_development_dependency 'rake', '~> 13.0'
  spec.add_development_dependency 'rspec', '~> 3.0'
  spec.add_development_dependency 'rubocop', '~> 1.76.0'
end
