# ActiveRecordMcp::Config.setup do |config|
#   config.projects_root_file_path = File.join("/Users/dak2/Dev/Sources/activerecord-mcp")
#   config.projects_models_file_path = "/models"
#   config.projects_db_file_path = "/db"
# end

module ActiveRecordMcp
  class Config
    attr_accessor :projects_root_file_path, :projects_models_file_path, :projects_db_file_path

    def initialize(&block)
      instance_eval(&block)
    end
  end
end
