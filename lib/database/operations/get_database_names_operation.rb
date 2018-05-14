require "database/operations"
require "database/commands/get_database_names_command"

module RavenDB
  class GetDatabaseNamesOperation < ServerOperation
    def initialize(start:, page_size:)
      @start = start
      @page_size = page_size
    end

    def get_command(conventions:)
      RavenDB::GetDatabaseNamesCommand.new(start: @start, page_size: @page_size)
    end
  end
end
