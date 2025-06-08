# frozen_string_literal: true

require 'open3'
require 'active_support/inflector/methods'

module ActiveRecordMcp
  module Tools
    class DescribeTable < MCP::Tool
      description 'Describe a table in the database'

      input_schema(
        properties: {
          table_name: {
            type: 'string',
            description: "Table name to describe (e.g., 'users', 'products'). Use snake_case, plural form. If omitted, returns complete database schema."
          }
        },
        required: ['table_name']
      )

      def self.call(server_context:, table_name:)
        config = server_context.respond_to?(:config) ? server_context.config : ActiveRecordMcp::Config.instance
        stdout_str, stderr_str, status = Open3.capture3(*capture3_args_for(
          model_name: classify(table_name),
          dir: config.projects_root_file_path
        ))
        if status.success?
          MCP::Tool::Response.new([{ type: 'text', text: stdout_str }])
        else
          MCP::Tool::Response.new([{ type: 'text', text: stderr_str }])
        end
      end

      def self.capture3_args_for(model_name:, dir:)
        ['ruby', '-e', "require './config/environment'; puts #{describe_table_query(model_name:)}.inspect", { chdir: dir }]
      end

      def self.classify(table_name)
        ActiveSupport::Inflector.classify(table_name)
      end

      def self.describe_table_query(model_name:)
        "#{model_name}.columns.map { |c| { name: c.name, type: c.type.to_s, sql_type: c.sql_type, null: c.null, default: c.default, limit: c.limit, precision: c.precision, scale: c.scale } }"
      end
    end
  end
end
