# frozen_string_literal: true

require 'active_record'

module ActiveRecordMcp
  class QueryBuilder
    def initialize
      load_rails_environment if rails_environment_available?
    end

    def fetch_records(natural_language_query)
      # Parse the natural language query and convert to ActiveRecord
      parsed_query = parse_query(natural_language_query)

      model_class = find_model_class(parsed_query[:model])
      return { error: "Model '#{parsed_query[:model]}' not found" } unless model_class

      begin
        query = build_activerecord_query(model_class, parsed_query)
        results = execute_query(query, parsed_query)

        {
          model: model_class.name,
          query: parsed_query,
          count: if results.respond_to?(:count)
                   results.count
                 else
                   (results.is_a?(Array) ? results.size : 1)
                 end,
          records: format_results(results)
        }
      rescue StandardError => e
        { error: "Query execution failed: #{e.message}" }
      end
    end

    private

    def rails_environment_available?
      defined?(Rails) || File.exist?('config/application.rb')
    end

    def load_rails_environment
      return if defined?(Rails) && Rails.application

      # Try to load Rails environment
      rails_root = ActiveRecordMcp.configuration.rails_root

      return unless File.exist?(File.join(rails_root, 'config', 'application.rb'))

      require File.join(rails_root, 'config', 'environment')
    end

    def parse_query(query)
      # Simple parsing logic - can be enhanced with NLP libraries
      query_lower = query.downcase

      # Extract model name (look for common patterns)
      model = extract_model_name(query_lower)

      # Extract conditions
      conditions = extract_conditions(query_lower)

      # Extract limit
      limit = extract_limit(query_lower)

      # Extract order
      order = extract_order(query_lower)

      {
        model: model,
        conditions: conditions,
        limit: limit,
        order: order,
        original: query
      }
    end

    def extract_model_name(query)
      # Look for common model patterns
      models = get_available_models

      # Try to find model name in the query
      models.find { |model| query.include?(model.downcase) } ||
        models.find { |model| query.include?(model.pluralize.downcase) } ||
        'User' # Default fallback
    end

    def extract_conditions(query)
      conditions = {}

      # Simple pattern matching for common conditions
      if query.match(/name.*?['""]([^'"]*)['""]/) || query.match(/named\s+([^\s]+)/)
        conditions[:name] =
          ::Regexp.last_match(1)
      end

      if query.match(/email.*?['""]([^'"]*)['""]/) || query.match(/with email\s+([^\s]+)/)
        conditions[:email] =
          ::Regexp.last_match(1)
      end

      conditions[:id] = ::Regexp.last_match(1).to_i if query.match(/id\s*=\s*(\d+)/) || query.match(/with id\s+(\d+)/)

      conditions
    end

    def extract_limit(query)
      if query.match(/(?:first|limit)\s+(\d+)/) || query.match(/(\d+)\s+(?:records|users|items)/)
        ::Regexp.last_match(1).to_i
      else
        10 # Default limit
      end
    end

    def extract_order(query)
      if query.include?('newest') || query.include?('recent')
        'created_at DESC'
      elsif query.include?('oldest')
        'created_at ASC'
      elsif query.include?('alphabetical')
        'name ASC'
      else
        'id ASC'
      end
    end

    def find_model_class(model_name)
      return nil unless model_name

      # Try to find the model class
      begin
        model_name.classify.constantize
      rescue NameError
        # Try common model names
        %w[User Post Article Comment Product Order].each do |common_model|
          next unless common_model.downcase == model_name.downcase

          begin
            return common_model.constantize
          rescue StandardError
            nil
          end
        end
        nil
      end
    end

    def get_available_models
      if defined?(Rails) && Rails.application
        Rails.application.eager_load!
        ApplicationRecord.descendants.map(&:name)
      else
        # Fallback to common model names
        %w[User Post Article Comment Product Order Customer]
      end
    end

    def build_activerecord_query(model_class, parsed_query)
      query = model_class.all

      # Apply conditions
      parsed_query[:conditions].each do |field, value|
        query = query.where(field => value) if model_class.column_names.include?(field.to_s)
      end

      # Apply order
      query = query.order(parsed_query[:order]) if parsed_query[:order]

      # Apply limit
      query = query.limit(parsed_query[:limit]) if parsed_query[:limit]

      query
    end

    def execute_query(query, _parsed_query)
      # Execute the query
      query.to_a
    end

    def format_results(results)
      case results
      when Array
        results.map { |record| format_record(record) }
      else
        format_record(results)
      end
    end

    def format_record(record)
      return record.to_s unless record.respond_to?(:attributes)

      # Get basic attributes, excluding sensitive information
      attrs = record.attributes.except('password_digest', 'encrypted_password', 'token')

      # Add some metadata
      {
        id: record.id,
        type: record.class.name,
        attributes: attrs,
        created_at: record.respond_to?(:created_at) ? record.created_at : nil,
        updated_at: record.respond_to?(:updated_at) ? record.updated_at : nil
      }
    end
  end
end
