require "open3"
require "bundler"

module ActiveRecordMcp
  module Tools
    class FetchRecords < FastMcp::Tool
      tool_name "fetch_records"
      description "Fetch ActiveRecord records using natural language queries"

      arguments do
        optional(:model_name).filled(:string).description("Model name to fetch records for (e.g., 'users', 'products'). Use snake_case, plural form. If omitted, returns complete database schema.")
      end

      def call(model_name:)
        # command = `bin/rails runner 'puts ActiveRecord::Base.connection.select_all("SELECT * FROM #{model_name}")`
        command = `bundle exec rails runner 'puts {"id": 1, "name": "dak2"}`
        output = Dir.chdir(projects_root_file_path) do
          stdout_str, stderr_str, status = Open3.capture3(subprocess_env, command)
          if status.success?
            return stdout_str
          else
            return stderr_str
          end
        end
      end

      private

      def projects_root_file_path
        @projects_root_file_path ||= File.expand_path("/Users/dak2/Dev/Sources/rails-sandbox")
      end

      def subprocess_env
        ENV.to_h.merge(Bundler.original_env).merge(
          "BUNDLE_GEMFILE" => File.join(projects_root_file_path, "Gemfile")
        )
      end
    end
  end
end
