module RavenDB
  class PutIndexesOperation < AdminOperation
    def initialize(indexes_to_add, *more_indexes_to_add)
      indexes = indexes_to_add.is_a?(Array) ? indexes_to_add : [indexes_to_add]

      if more_indexes_to_add.is_a?(Array) && !more_indexes_to_add.empty?
        indexes.concat(more_indexes_to_add)
      end

      super()
      @indexes = indexes
    end

    def get_command(conventions:, store: nil, http_cache: nil)
      PutIndexesCommand.new(@indexes)
    end
  end
end
