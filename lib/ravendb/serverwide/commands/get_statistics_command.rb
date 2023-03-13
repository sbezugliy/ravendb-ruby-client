module RavenDB
  class GetStatisticsCommand < RavenCommand
    def initialize(check_for_failures: false, debug_tag: false)
      super()
      @check_for_failures = check_for_failures
      @debug_tag = debug_tag
    end

    def create_request(server_node)
      assert_node(server_node)

      end_point = "/databases/#{server_node.database}/stats?"
      end_point += @debug_tag.to_s if @debug_tag
      end_point += "&failure=check" if @check_for_failures

      Net::HTTP::Get.new(end_point)
    end

    def read_request?
      true
    end

    def parse_response(json, from_cache:, conventions: nil)
      @mapper.read_value(json, DatabaseStatistics, nested: {size_on_disk: Size, indexes: IndexInformation}, conventions:)
    end
  end

  class DatabaseStatistics
    attr_accessor :count_of_indexes, :count_of_documents, :count_of_revision_documents, :count_of_tombstones, :count_of_documents_conflicts, :count_of_conflicts, :count_of_attachments,
                  :count_of_unique_attachments, :database_change_vector, :database_id, :number_of_transaction_merger_queue_operations, :is64_bit, :pager, :last_doc_etag, :last_indexing_time, :size_on_disk, :indexes
  end

  class Size
    attr_accessor :size_in_bytes, :humane_size
  end

  class IndexInformation
    attr_accessor :name, :state, :lock_mode, :priority, :type, :last_indexing_time

    def stale?
      @is_stale
    end
  end
end
