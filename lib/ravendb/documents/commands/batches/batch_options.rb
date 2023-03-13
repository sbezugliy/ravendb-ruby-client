module RavenDB
  class BatchOptions
    attr_accessor :wait_for_replicas, :number_of_replicas_to_wait_for, :wait_for_replicas_timeout, :majority, :throw_on_timeout_in_wait_for_replicas, :wait_for_indexes,
                  :wait_for_indexes_timeout, :throw_on_timeout_in_wait_for_indexes, :wait_for_specific_indexes

    def wait_for_replicas?
      wait_for_replicas
    end

    def majority?
      majority
    end

    def throw_on_timeout_in_wait_for_replicas?
      throw_on_timeout_in_wait_for_replicas
    end

    def wait_for_indexes?
      wait_for_indexes
    end

    def throw_on_timeout_in_wait_for_indexes?
      throw_on_timeout_in_wait_for_indexes
    end
  end
end
