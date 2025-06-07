module ActiveRecordMcp
  class Config
    attr_accessor :projects_root_file_path, :projects_models_file_path, :projects_db_file_path

    def initialize
      @projects_root_file_path = Dir.pwd
      @projects_models_file_path = "app/models"
      @projects_db_file_path = "db"
    end

    def self.setup
      yield(instance) if block_given?
    end

    def self.instance
      @instance ||= new
    end
  end
end
