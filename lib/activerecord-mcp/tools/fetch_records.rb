require "open3"
require "bundler"

module ActiveRecordMcp
  module Tools
    class FetchRecords < FastMcp::Tool
      tool_name "fetch_records"
      description "Fetch ActiveRecord records using natural language queries"

      arguments do
        optional(:model_name).filled(:string).description("Model name to fetch records for (e.g., 'users', 'products'). Use snake_case, plural form. If omitted, returns complete database schema.")
        optional(:query).filled(:string).description("Query to fetch records for (e.g., 'find all users created today', 'get the user with email john@example.com'). If omitted, returns all records.")
      end

      def call(model_name:, query:)
        command = "bin/rails runner 'puts ActiveRecord::Base.connection.select_all(`SELECT * FROM #{model_name}`)'"
        stdout_str, stderr_str, status = Open3.capture3(subprocess_env, command, chdir: "/Users/dak2/Dev/Sources/rails-sandbox")

        if status.success?
          return stdout_str
        else
          return stderr_str
        end
      end

      private

      def projects_root_file_path
        @projects_root_file_path ||= ActiveRecordMcp.configuration.projects_root_file_path
      end

      def subprocess_env
        subprocess_env = ENV.to_h.merge(Bundler.original_env).merge(
          "BUNDLE_GEMFILE" => File.join(projects_root_file_path, "Gemfile")
        )
      end
    end
  end
end
