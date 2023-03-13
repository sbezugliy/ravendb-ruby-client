module RavenDatabaseTest
  def self.setup(context, _example)
    context.instance_eval do
      store.conventions.disable_topology_updates = false
      @_index_map =
        "from doc in docs " \
        "select new{" \
        "Tag = doc[\"@metadata\"][\"@collection\"]," \
        "LastModified = (DateTime)doc[\"@metadata\"][\"Last-Modified\"]," \
        "LastModifiedTicks = ((DateTime)doc[\"@metadata\"][\"Last-Modified\"]).Ticks}"

      database_record = RavenDB::DatabaseDocument.new(current_database, "Raven/DataDir": "test")
      store.maintenance.server.send(RavenDB::CreateDatabaseOperation.new(database_record:))
      @_request_executor = store.get_request_executor
    end
  end

  def self.teardown(context, _example)
    context.instance_eval do
      store.maintenance.server.send(RavenDB::DeleteDatabaseOperation.new(database_name: current_database, hard_delete: true))
      @_request_executor = nil
      @_index_map = nil
    end
  end
end

module RavenDatabaseTestHelpers
  def request_executor
    @_request_executor
  end

  def index_map
    @_index_map
  end
end
