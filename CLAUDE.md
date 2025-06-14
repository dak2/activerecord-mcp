# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

ActiveRecord MCP is a Ruby gem that provides a Model Context Protocol (MCP) server for ActiveRecord models. It enables natural language querying of Rails application databases through the MCP protocol, allowing clients like Claude Desktop to interact with ActiveRecord models using human-readable queries.

## Core Architecture

The gem follows a modular structure:

- **Main module (`lib/activerecord-mcp.rb`)**: Entry point that loads core components
- **Configuration (`lib/activerecord-mcp/config.rb`)**: Singleton configuration class managing Rails project paths
- **Tools (`lib/activerecord-mcp/tools/`)**: MCP tool implementations using the official mcp gem
- **Executable (`exe/activerecord-mcp`)**: MCP server entry point with MCP::Server and StdioTransport setup

### Key Components

#### SelectRecords Tool
The primary tool (`lib/activerecord-mcp/tools/select_records.rb`) inherits from `MCP::Tool` and uses Ruby subprocess execution to run ActiveRecord queries within Rails environments. It defines input schema using JSON Schema format and returns `MCP::Tool::Response` objects.

#### Configuration System
The Config class uses a singleton pattern to manage Rails project paths. The executable hardcodes a specific Rails sandbox path but the configuration is designed to be flexible.

#### MCP Integration
Built on the official `mcp` gem, requiring ActiveRecord >= 8.0 and ActiveSupport >= 8.0.

## Development Commands

### Testing
```bash
# Run all tests
bundle exec rake spec

# Run specific test file
bundle exec rspec spec/path/to/test_spec.rb

# Run with focus on specific examples
bundle exec rspec spec/path/to/test_spec.rb --tag focus
```

### Code Quality
```bash
# Run RuboCop linting
bundle exec rubocop --fix
```

### Installation and Setup
```bash
# Install dependencies
bundle install

# Build gem locally
bundle exec rake build

# Install gem locally for testing
bundle exec rake install
```

### Running the MCP Server
```bash
# From project root
./exe/activerecord-mcp

# Or after installation
activerecord-mcp
```

## Testing Framework

- Uses RSpec 3.x for testing
- Spec helper resets Config singleton between tests
- Integration tests in `spec/integration/` test actual Rails environment interaction
- Unit tests focus on individual components

## Important Implementation Details

### Query Execution Pattern
The SelectRecords tool uses `Open3.capture3` to execute Ruby code in subprocesses, loading the Rails environment with `require './config/environment'`. This approach allows the MCP server to run outside the Rails application while still accessing its models.

### Security Considerations
- All queries are read-only (uses `.inspect` for output formatting)
- Sensitive fields like `password_digest` are excluded from responses
- Query execution is limited to prevent resource exhaustion

### Model Discovery
The system attempts to classify table names using ActiveSupport::Inflector and falls back to common model names when Rails environment isn't fully loaded.

### Tool Implementation Notes
- Tools inherit from `MCP::Tool` and define class methods
- Input validation uses JSON Schema format with `input_schema()` 
- Tool responses return `MCP::Tool::Response` objects with structured content
- The server uses `MCP::Transports::StdioTransport` for communication
