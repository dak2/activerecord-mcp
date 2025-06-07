require "open3"
require "bundler"
require "active_support/inflector/methods"

module ActiveRecordMcp
  module Tools
    class SelectRecords < FastMcp::Tool
      tool_name "select_records"
      description "Select ActiveRecord records using natural language queries"

      arguments do
        optional(:model_name).filled(:string).description("Model name to fetch records for (e.g., 'users', 'products'). Use snake_case, plural form. If omitted, returns complete database schema.")
        optional(:filter_condition).filled(:string).description("WHERE condition to filter records (e.g., 'content IS NOT NULL', 'status = \"published\"')")
        optional(:order_by).filled(:string).description("ORDER BY clause (e.g., 'created_at DESC', 'name ASC')")
        optional(:limit).filled(:integer).description("Maximum number of records to return (e.g., 5, 10)")
        optional(:count_only).filled(:bool).description("Return only the count/size of records instead of the actual records (e.g., true for 'show the size of posts')")
      end

      def call(model_name: nil, filter_condition: nil, order_by: nil, limit: nil, count_only: false)
        stdout_str, stderr_str, status = Open3.capture3(*capture3_args_for(
          model_name: model_name, 
          filter_condition: filter_condition,
          order_by: order_by,
          limit: limit,
          count_only: count_only,
          dir: projects_root_file_path
        ))
        if status.success?
          return stdout_str
        else
          return stderr_str
        end
      end

      private

      def projects_root_file_path
        ActiveRecordMcp::Config.instance.projects_root_file_path
      end

      def capture3_args_for(model_name: nil, filter_condition: nil, order_by: nil, limit: nil, count_only: false, dir: projects_root_file_path)
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

      def build_query_chain(model_class, filter_condition, order_by, limit, count_only)
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

      def classify(table_name)
        ActiveSupport::Inflector.classify(table_name)
      end
    end
  end
end
