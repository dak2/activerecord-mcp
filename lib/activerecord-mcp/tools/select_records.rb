require "open3"
require "bundler"

module ActiveRecordMcp
  module Tools
    class SelectRecords < FastMcp::Tool
      tool_name "select_records"
      description "Select ActiveRecord records using natural language queries"

      arguments do
        optional(:model_name).filled(:string).description("Model name to fetch records for (e.g., 'users', 'products'). Use snake_case, plural form. If omitted, returns complete database schema.")
      end

      def call(model_name:)
        stdout_str, stderr_str, status = Open3.capture3(*capture3_args_for(dir: projects_root_file_path))
        if status.success?
          return stdout_str
        else
          return stderr_str
        end
      end

      private

      def projects_root_file_path
        @projects_root_file_path ||= File.expand_path("/Users/dak2/Dev/Sources/rails-sandbox")
      end

      def capture3_args_for(dir: projects_root_file_path)
        ["ruby", "-e", "require './config/environment'; puts Post.all.inspect", { chdir: dir }]
      end
    end
  end
end
