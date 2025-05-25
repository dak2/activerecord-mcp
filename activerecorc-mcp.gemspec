require_relative "lib/activerecord-mcp/version"

Gem::Specification.new do |spec|
  spec.name = "activerecord-mcp"
  spec.version = ActiveRecordMcp::VERSION
  spec.authors = ["Your Name"]
  spec.email = ["your.email@example.com"]
  
  spec.summary = "MCP server for ActiveRecord operations"
  spec.description = "A Model Context Protocol server that provides natural language querying capabilities for ActiveRecord models"
  spec.homepage = "https://github.com/yourusername/activerecord-mcp"
  spec.license = "MIT"
  spec.required_ruby_version = Gem::Requirement.new(">= 3.0.0")
  
  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = spec.homepage
  spec.metadata["changelog_uri"] = "#{spec.homepage}/blob/main/CHANGELOG.md"
  
  # Specify which files should be added to the gem when it is released.
  spec.files = Dir.chdir(File.expand_path(__dir__)) do
    `git ls-files -z`.split("\x0").reject { |f| f.match(%r{\A(?:test|spec|features)/}) }
  end
  spec.bindir = "exe"
  spec.executables = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]
  
  # Dependencies
  spec.add_dependency "mcp-rb", "~> 0.1"
  spec.add_dependency "activerecord", ">= 8.0"
  spec.add_dependency "railties", ">= 8.0"
  
  # Development dependencies
  spec.add_development_dependency "rake", "~> 13.0"
  spec.add_development_dependency "rspec", "~> 3.0"
end
