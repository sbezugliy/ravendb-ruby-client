require "constants/documents"
require "constants/database"
require "active_support/core_ext/array/wrap"

module RavenDB
  class IndexDefinition
    def initialize(name:, index_map:, configuration: {}, reduce: 0, lock_mode: nil, priority: nil, is_test_index: false, fields: {})
      @_name = name
      @configuration = configuration
      @reduce = reduce
      @lock_mode = lock_mode
      @priority = priority
      @is_test_index = is_test_index
      @fields = fields
      @maps = Array.wrap(index_map)
    end

    def name
      @_name
    end

    def type
      result = "Map"

      if @_name&.start_with?("Auto/")
        result = "Auto#{result}"
      end

      if @reduce > 0
        result += "Reduce"
      end

      result
    end

    def map_reduce?
      @reduce > 0
    end

    def map
      @maps.length ? @maps.first : nil
    end

    def map=(value)
      if @maps.size
        @maps.pop
      end

      @maps.push(value)
    end

    def to_json(*_args)
      fields_json = {}

      @fields.each do |field, definition|
        fields_json[field] = definition.to_json
      end

      {
        "Configuration" => @configuration,
        "Fields" => fields_json,
        "IsTestIndex" => @is_test_index,
        "LockMode" => @lock_mode,
        "Maps" => @maps,
        "Name" => @_name,
        "Reduce" => @reduce,
        "OutputReduceToCollection" => nil,
        "Priority" => @priority || IndexPriority::NORMAL,
        "Type" => type
      }
    end
  end

  class IndexFieldOptions
    def initialize(indexing = nil, storage = nil, suggestions = nil, term_vector = nil, analyzer = nil)
      @indexing = indexing
      @storage = storage
      @suggestions = suggestions
      @term_vector = term_vector
      @analyzer = analyzer
    end

    def to_json(*_args)
      storage = @storage ? "Yes" : "No" unless @storage.nil?

      {
        "Analyzer" => @analyzer,
        "Indexing" => @indexing,
        "Spatial" => nil,
        "Storage" => storage,
        "Suggestions" => @suggestions,
        "TermVector" => @term_vector
      }
    end
  end
end
