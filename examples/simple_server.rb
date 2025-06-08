#!/usr/bin/env ruby
# frozen_string_literal: true

# Simple example of how to use activerecord-mcp in a standalone script
# This demonstrates usage outside of a full Rails application

require 'bundler/setup'
require 'active_record'
require_relative '../lib/activerecord_mcp'

# Setup a simple in-memory SQLite database for demonstration
ActiveRecord::Base.establish_connection(
  adapter: 'sqlite3',
  database: ':memory:'
)

# Create some sample models
class ApplicationRecord < ActiveRecord::Base
  primary_abstract_class
end

class User < ApplicationRecord
  validates :name, presence: true
  validates :email, presence: true, uniqueness: true
end

class Post < ApplicationRecord
  belongs_to :user
  validates :title, presence: true
end

# Create the database schema
ActiveRecord::Schema.define do
  create_table :users do |t|
    t.string :name, null: false
    t.string :email, null: false
    t.integer :age
    t.timestamps
  end

  create_table :posts do |t|
    t.string :title, null: false
    t.text :content
    t.references :user, null: false, foreign_key: true
    t.timestamps
  end

  add_index :users, :email, unique: true
end

# Seed some sample data
users = [
  { name: 'John Doe', email: 'john@example.com', age: 30 },
  { name: 'Jane Smith', email: 'jane@example.com', age: 25 },
  { name: 'Bob Wilson', email: 'bob@example.com', age: 35 }
]

users.each do |user_attrs|
  user = User.create!(user_attrs)

  # Create some posts for each user
  2.times do |i|
    user.posts.create!(
      title: "#{user.name}'s Post ##{i + 1}",
      content: "This is some sample content for post #{i + 1} by #{user.name}"
    )
  end
end

puts "✓ Created #{User.count} users and #{Post.count} posts"

# Configure and start the MCP server
ActiveRecordMcp.configure do |config|
  config.rails_root = Dir.pwd
end

puts '🚀 Starting ActiveRecord MCP server with sample data...'
puts "📊 Available models: #{[User, Post].map(&:name).join(', ')}"
puts ''
puts 'Try these queries:'
puts "  - 'find all users'"
puts "  - 'get user with email john@example.com'"
puts "  - 'show me the newest posts'"
puts "  - 'find users older than 30'"
puts ''

# Start the server
ActiveRecordMcp::Server.start
