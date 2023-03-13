module RavenDB
  class SaveChangesData
    attr_reader :deferred_commands, :session_commands, :entities, :options, :deferred_commands_map

    def initialize(session)
      @deferred_commands = session.deferred_commands.dup
      @deferred_commands_map = session.deferred_commands_map.dup
      @options = session._save_changes_options
      @entities = []
      @session_commands = []
    end
  end
end
