# ActiveRecord MCP

A Model Context Protocol (MCP) server that provides natural language querying capabilities for ActiveRecord models in Rails applications.

## Features

- 🗣️ **Natural Language Queries**: Ask for records using plain English
- 🔍 **Model Introspection**: List and describe your ActiveRecord models  
- 🚀 **Rails Integration**: Seamlessly works with existing Rails applications
- 🛠️ **MCP Compatible**: Works with Claude Desktop and other MCP clients

## Installation

Add this line to your Rails application's Gemfile:

```ruby
gem 'activerecord-mcp'
```

And then execute:

```bash
$ bundle install
```

Or install it yourself as:

```bash
$ gem install activerecord-mcp
```

## Usage

### Starting the MCP Server

From your Rails application directory:

```bash
$ activerecord-mcp
```

This will start the MCP server and load your Rails environment, making all your models available for querying.

### Available Tools

#### `select_records`

Query your ActiveRecord models using natural language:

```json
{
  "tool": "select_records",
  "arguments": {
    "query": "find all users created today",
    "limit": 10
  }
}
```

**Example queries:**
- `"find all users created today"`
- `"get the user with email john@example.com"`
- `"show me the 5 most recent posts"`  
- `"find users named John"`
- `"get all orders from last week"`

#### `list_models`

Get information about all available ActiveRecord models:

```json
{
  "tool": "list_models",
  "arguments": {}
}
```

#### `describe_model`

Get detailed information about a specific model:

```json
{
  "tool": "describe_model", 
  "arguments": {
    "model_name": "User"
  }
}
```

### Configuration

You can configure the gem in your Rails application:

```ruby
# config/initializers/activerecord_mcp.rb
ActiveRecordMcp.configure do |config|
  config.rails_root = Rails.root
  config.models_path = "app/models"
end
```

## Using with Claude Desktop

Add this to your Claude Desktop MCP configuration:

```json
{
  "mcpServers": {
    "activerecord": {
      "command": "activerecord-mcp",
      "cwd": "/path/to/your/rails/app"
    }
  }
}
```

Then restart Claude Desktop. You'll be able to ask questions like:

> "Show me all users created in the last week"

> "What models are available in this Rails app?"

> "Find the user with email admin@example.com"

## Query Examples

The `select_records` tool supports various natural language patterns:

### Basic Queries
- `"find all users"` → `User.all.limit(10)`
- `"get 20 users"` → `User.limit(20)`
- `"show me users"` → `User.all.limit(10)`

### Filtered Queries  
- `"users with name John"` → `User.where(name: "John")`
- `"user with email john@example.com"` → `User.where(email: "john@example.com")`
- `"user with id 123"` → `User.where(id: 123)`

### Ordered Queries
- `"newest users"` → `User.order(created_at: :desc)`
- `"oldest posts"` → `Post.order(created_at: :asc)`  
- `"users alphabetically"` → `User.order(name: :asc)`

### Complex Queries
- `"find 5 newest users named John"` → `User.where(name: "John").order(created_at: :desc).limit(5)`

## Response Format

Successful queries return:

```json
{
  "success": true,
  "model": "User",
  "count": 3,
  "records": [
    {
      "id": 1,
      "type": "User", 
      "attributes": {
        "name": "John Doe",
        "email": "john@example.com",
        "created_at": "2024-01-15T10:30:00Z"
      },
      "created_at": "2024-01-15T10:30:00Z",
      "updated_at": "2024-01-15T10:30:00Z"
    }
  ],
  "query": "find users named John",
  "parsed_query": {
    "model": "User",
    "conditions": { "name": "John" },
    "limit": 10,
    "order": "id ASC"
  }
}
```

## Security

- Sensitive fields like `password_digest`, `encrypted_password`, and `token` are automatically excluded from responses
- The server runs read-only queries and cannot modify your data
- All queries are limited to prevent resource exhaustion

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake test` to run the tests.

To install this gem onto your local machine, run `bundle exec rake install`.

### Running Tests

```bash
$ bundle exec rake test
```

### Code Style

```bash
$ bundle exec standardrb --fix
```

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/yourusername/activerecord-mcp.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## Changelog

See [CHANGELOG.md](CHANGELOG.md) for version history.
