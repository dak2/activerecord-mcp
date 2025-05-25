require "mcp"
require_relative "query_builder"

module ActiveRecordMcp
  class Server
    def self.start
      new.setup_mcp_server
    end
    
    def setup_mcp_server
      query_builder = QueryBuilder.new
      
      # MCP Server configuration
      name "activerecord-mcp"
      version ActiveRecordMcp::VERSION
      
      # Main tool: fetch_records
      tool "fetch_records" do
        description "Fetch ActiveRecord records using natural language queries"
        argument :query, String, required: true, description: "Natural language description of the records to fetch (e.g., 'find all users created today', 'get the user with email john@example.com')"
        argument :limit, Integer, required: false, description: "Maximum number of records to return (default: 10)"
        
        call do |args|
          begin
            # Override limit if provided
            if args[:limit] && args[:limit] > 0
              modified_query = "#{args[:query]} limit #{args[:limit]}"
              result = query_builder.fetch_records(modified_query)
            else
              result = query_builder.fetch_records(args[:query])
            end
            
            # Format response for MCP
            if result[:error]
              {
                success: false,
                error: result[:error],
                query: args[:query]
              }
            else
              {
                success: true,
                model: result[:model],
                count: result[:count],
                records: result[:records],
                query: args[:query],
                parsed_query: result[:query]
              }
            end
          rescue => e
            {
              success: false,
              error: "Server error: #{e.message}",
              query: args[:query]
            }
          end
        end
      end
      
      # Additional tool: list_models
      tool "list_models" do
        description "List available ActiveRecord models in the Rails application"
        
        call do |args|
          begin
            if defined?(Rails) && Rails.application
              Rails.application.eager_load!
              models = ApplicationRecord.descendants.map do |model|
                {
                  name: model.name,
                  table_name: model.table_name,
                  columns: model.column_names,
                  associations: model.reflect_on_all_associations.map { |assoc| 
                    { name: assoc.name, type: assoc.class.name.demodulize } 
                  }
                }
              end
              
              {
                success: true,
                models: models,
                count: models.size
              }
            else
              {
                success: false,
                error: "Rails application not available. Make sure you're running this from a Rails project directory."
              }
            end
          rescue => e
            {
              success: false,
              error: "Failed to load models: #{e.message}"
            }
          end
        end
      end
      
      # Tool: describe_model
      tool "describe_model" do
        description "Get detailed information about a specific ActiveRecord model"
        argument :model_name, String, required: true, description: "Name of the model to describe (e.g., 'User', 'Post')"
        
        call do |args|
          begin
            model_class = args[:model_name].classify.constantize
            
            {
              success: true,
              model: {
                name: model_class.name,
                table_name: model_class.table_name,
                primary_key: model_class.primary_key,
                columns: model_class.columns.map { |col|
                  {
                    name: col.name,
                    type: col.type,
                    sql_type: col.sql_type,
                    null: col.null,
                    default: col.default
                  }
                },
                associations: model_class.reflect_on_all_associations.map { |assoc|
                  {
                    name: assoc.name,
                    type: assoc.class.name.demodulize,
                    class_name: assoc.class_name,
                    foreign_key: assoc.foreign_key
                  }
                },
                validations: model_class.validators.map { |v|
                  {
                    type: v.class.name.demodulize,
                    attributes: v.attributes,
                    options: v.options.except(:class)
                  }
                }
              }
            }
          rescue NameError
            {
              success: false,
              error: "Model '#{args[:model_name]}' not found"
            }
          rescue => e
            {
              success: false,
              error: "Failed to describe model: #{e.message}"
            }
          end
        end
      end
      
      # Resource for Rails configuration
      resource "rails://config" do
        name "Rails Configuration"
        description "Current Rails application configuration"
        
        call do
          if defined?(Rails) && Rails.application
            {
              rails_version: Rails.version,
              environment: Rails.env,
              root: Rails.root.to_s,
              database_config: Rails.configuration.database_configuration[Rails.env]&.except("password"),
              time_zone: Rails.application.config.time_zone
            }
          else
            { error: "Rails application not available" }
          end
        end
      end
    end
  end
end
