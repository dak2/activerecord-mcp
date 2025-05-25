require_relative "activerecord-mcp/version"
require_relative "activerecord-mcp/config"
require_relative "activerecord-mcp/tools/fetch_records"
# require_relative "activerecord-mcp/query_builder"

module ActiveRecordMcp
  class Error < StandardError; end
  private attr_reader :configuration

  def self.configuration(&block)
    @configuration ||= Config.new(&block)
  end
end
