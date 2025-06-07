require_relative "activerecord-mcp/version"
require_relative "activerecord-mcp/config"
require_relative "activerecord-mcp/tools/select_records"
# require_relative "activerecord-mcp/query_builder"

module ActiveRecordMcp
  class Error < StandardError; end

  def self.configuration(&block)
    Config.setup(&block)
  end
end
