require "open3"
require "bundler"
require "active_support/inflector/methods"

module ActiveRecordMcp
  module Tools
    class SelectRecords < MCP::Tool
      description "Select ActiveRecord records using natural language queries"

      input_schema(
        properties: {
          model_name: {
            type: "string",
            description: "Model name to fetch records for (e.g., 'users', 'products'). Use snake_case, plural form. If omitted, returns complete database schema."
          },
          filter_condition: {
            type: "string",
            description: "WHERE condition to filter records (e.g., 'content IS NOT NULL', 'status = \"published\"')"
          },
          order_by: {
            type: "string",
            description: "ORDER BY clause (e.g., 'created_at DESC', 'name ASC')"
          },
          limit: {
            type: "integer",
            description: "Maximum number of records to return (e.g., 5, 10)"
          },
          count_only: {
            type: "boolean",
            description: "Return only the count/size of records instead of the actual records (e.g., true for 'show the size of posts')"
          }
        },
        required: []
      )

      def self.call(model_name: nil, filter_condition: nil, order_by: nil, limit: nil, count_only: false, server_context:)
        stdout_str, stderr_str, status = Open3.capture3(*capture3_args_for(
          model_name: model_name, 
          filter_condition: filter_condition,
          order_by: order_by,
          limit: limit,
          count_only: count_only,
          dir: projects_root_file_path
        ))
        if status.success?
          MCP::Tool::Response.new([{ type: "text", text: stdout_str }])
        else
          MCP::Tool::Response.new([{ type: "text", text: stderr_str }])
        end
      end

      private

      def self.projects_root_file_path
        ActiveRecordMcp::Config.instance.projects_root_file_path
      end

      def self.capture3_args_for(model_name: nil, filter_condition: nil, order_by: nil, limit: nil, count_only: false, dir: projects_root_file_path)
        raise "Model name is required" if model_name.nil?

        query_parts = build_query_chain(classify(model_name), filter_condition, order_by, limit, count_only)
        ruby_code = if count_only
          "require './config/environment'; puts #{query_parts}"
        else
          "require './config/environment'; puts #{query_parts}.inspect"
        end
        
        ["ruby", "-e", ruby_code, { chdir: dir }]
      rescue => e
        raise "Error selecting records for model '#{model_name}': #{e.message}"
      end

      def self.build_query_chain(model_class, filter_condition, order_by, limit, count_only)
        query = "#{model_class}.all"
        
        if filter_condition
          query += ".where(\"#{filter_condition}\")"
        end
        
        if order_by && !count_only
          query += ".order(\"#{order_by}\")"
        end
        
        if limit && !count_only
          query += ".limit(#{limit})"
        end
        
        if count_only
          query += ".count"
        end
        
        query
      end

      def self.classify(table_name)
        ActiveSupport::Inflector.classify(table_name)
      end
    end
  end
end
