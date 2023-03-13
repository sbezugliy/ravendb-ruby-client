module RavenDB
  class MultiDatabaseHiLoIdGenerator
    def initialize(store, conventions)
      @store = store
      @conventions = conventions
      @_generators = ConcurrentHashMap.new
    end

    def generate_document_id(db_name, entity)
      db = (db_name.nil? ? @store.database : db_name)
      generator = @_generators.compute_if_absent(db) do |x|
        generate_multi_type_hi_lo_func(x)
      end
      generator.generate_document_id(entity)
    end

    def generate_multi_type_hi_lo_func(db_name)
      MultiTypeHiLoIdGenerator.new(@store, db_name, @conventions)
    end

    def return_unused_range
      @_generators.each_value(&:return_unused_range)
    end
  end
end
