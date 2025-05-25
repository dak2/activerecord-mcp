require_relative "activerecord_mcp/version"
require_relative "activerecord_mcp/server"
require_relative "activerecord_mcp/query_builder"

module ActiveRecordMcp
  class Error < StandardError; end
  
  class Configuration
    attr_accessor :rails_root, :database_url, :models_path
    
    def initialize
      @rails_root = Dir.pwd
      @models_path = "app/models"
    end
  end
  
  class << self
    attr_accessor :configuration
  end
  
  def self.configuration
    @configuration ||= Configuration.new
  end
  
  def self.configure
    yield(configuration)
  end
end
