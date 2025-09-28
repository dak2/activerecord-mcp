# frozen_string_literal: true

require 'open3'
require 'bundler'
require 'active_support/inflector/methods'

module ActiveRecordMcp
  module Tools
    class SelectRecords < MCP::Tool
      description 'Select ActiveRecord records using natural language queries'

      input_schema(
        properties: {
          model_name: {
            type: 'string',
            description: "Model name to fetch records for (e.g., 'users', 'products'). Use snake_case, plural form. If omitted, returns complete database schema."
          },
          filter_condition: {
            type: 'string',
            description: "WHERE condition to filter records (e.g., 'content IS NOT NULL', 'status = \"published\"')"
          },
          stats_statement: {
            type: 'string',
            description: "COUNT, SUM, AVG, MIN, MAX aggregation instead of full records. Use downcase (e.g., 'count', 'sum(`column_name`)', 'avg(`column_name`)', 'min(`column_name`)', 'max(`column_name`)'"
          },
          order_by: {
            type: 'string',
            description: "ORDER BY clause (e.g., 'created_at DESC', 'name ASC')"
          },
          limit: {
            type: 'integer',
            description: 'Maximum number of records to return (e.g., 5, 10)'
          }
        },
        required: ['model_name']
      )

      def self.call(server_context:, model_name:, filter_condition: nil, stats_statement: nil, order_by: nil, limit: nil)
        stdout_str, stderr_str, status = Open3.capture3(*capture3_args_for(
          model_name: model_name,
          filter_condition: filter_condition,
          order_by: order_by,
          limit: limit,
          stats_statement: stats_statement,
          dir: projects_root_file_path
        ))
        if status.success?
          MCP::Tool::Response.new([{ type: 'text', text: stdout_str }])
        else
          MCP::Tool::Response.new([{ type: 'text', text: stderr_str }])
        end
      end

      def self.projects_root_file_path
        ActiveRecordMcp::Config.instance.projects_root_file_path
      end

      def self.capture3_args_for(model_name:, filter_condition: nil, stats_statement: nil, order_by: nil, limit: nil,
                                 dir: projects_root_file_path)
        raise ArgumentError, 'Model name is required' if model_name.nil?

        query_parts = build_query_chain(classify(model_name), filter_condition, stats_statement, order_by, limit)
        ruby_code = "require './config/environment'; puts #{query_parts}.inspect"

        ['ruby', '-e', ruby_code, { chdir: dir }]
      rescue StandardError => e
        raise "Error selecting records for model '#{model_name}': #{e.message}"
      end

      def self.build_query_chain(model_class, filter_condition, stats_statement, order_by, limit)
        query = "#{model_class}.all"

        if filter_condition
          # Validate and sanitize filter condition to prevent SQL injection
          return nil unless validate_sql_condition(filter_condition)

          query += ".where(\"#{filter_condition}\")"
        end

        if stats_statement
          # Validate and sanitize stats statement to prevent SQL injection
          return nil unless validate_sql_condition(stats_statement)

          query += ".#{stats_statement.downcase}"
          return query  # If stats_statement is provided, we don't need order or limit
        end

        if order_by
          # Validate and sanitize order_by to prevent SQL injection
          sanitized_order = sanitize_order_by(order_by)
          query += ".order(\"#{sanitized_order}\")" if sanitized_order
        end

        query += ".limit(#{limit.to_i})" if limit

        query
      end

      def self.validate_sql_condition(condition)
        return false unless condition.is_a?(String)

        # Block dangerous SQL operations while allowing legitimate WHERE clauses
        dangerous_patterns = [
          /\b(DROP|DELETE|UPDATE|INSERT|ALTER|CREATE|TRUNCATE)\b/i,
          /;\s*\w/,  # Semicolon followed by word (potential SQL injection)
          /--/,      # SQL comments
          %r{/\*}, # SQL block comments
          /\bEXEC\b/i,  # EXEC statements
          /\bSP_\w+/i,  # Stored procedures
          /\\\\/,    # Backslash escaping attempts
          /\x00/     # Null bytes
        ]

        dangerous_patterns.none? { |pattern| condition.match?(pattern) }
      end

      def self.sanitize_order_by(order_by)
        return nil unless order_by.is_a?(String)

        # Allow only alphanumeric characters, underscores, dots, spaces, commas, and ASC/DESC
        # This prevents injection while allowing valid column names and sort directions
        return unless order_by.match?(/\A[a-zA-Z0-9_.,\s]+(?:\s+(?:ASC|DESC|asc|desc))?\z/)

        order_by.strip
      end

      def self.classify(table_name)
        ActiveSupport::Inflector.classify(table_name)
      end
    end
  end
end
