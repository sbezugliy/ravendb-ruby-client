module RavenDB
  class IndexQuery
    DEFAULT_TIMEOUT = 15 * 1000
    DEFAULT_PAGE_SIZE = (2**31) - 1

    attr_accessor :start, :page_size
    attr_reader :query, :query_parameters, :wait_for_non_stale_results,
                :wait_for_non_stale_results_as_of_now, :wait_for_non_stale_results_timeout

    def initialize(query = "", query_parameters = {}, page_size = DEFAULT_PAGE_SIZE, skipped_results = 0, options = {})
      @query = query
      @query_parameters = query_parameters || {}
      @page_size = page_size || DEFAULT_PAGE_SIZE
      @start = skipped_results || 0
      @cut_off_etag = options[:cut_off_etag]
      @wait_for_non_stale_results = options[:wait_for_non_stale_results] || false
      @wait_for_non_stale_results_as_of_now = options[:wait_for_non_stale_results_as_of_now] || false
      @wait_for_non_stale_results_timeout = options[:wait_for_non_stale_results_timeout]

      unless @page_size.is_a?(Numeric)
        @page_size = DEFAULT_PAGE_SIZE
      end

      if (@wait_for_non_stale_results ||
          @wait_for_non_stale_results_as_of_now) &&
         !@wait_for_non_stale_results_timeout

        @wait_for_non_stale_results_timeout = DEFAULT_TIMEOUT
      end
    end

    def query_hash
      buffer = "#{@query}#{@page_size}#{@start}"
      buffer += (@wait_for_non_stale_results ? "1" : "0")
      buffer += (@wait_for_non_stale_results_as_of_now ? "1" : "0")

      if @wait_for_non_stale_results
        buffer += @wait_for_non_stale_results_timeout.to_s
      end

      Digest::SHA256.hexdigest(buffer)
    end

    def to_json(*_args)
      json = {
        "Query" => @query,
        "QueryParameters" => @query_parameters
      }

      unless @start.nil?
        json["Start"] = @start
      end

      unless @page_size.nil?
        json["PageSize"] = @page_size
      end

      unless @cut_off_etag.nil?
        json["CutoffEtag"] = @cut_off_etag
      end

      unless @wait_for_non_stale_results.nil?
        json["WaitForNonStaleResults"] = true
      end

      unless @wait_for_non_stale_results_as_of_now.nil?
        json["WaitForNonStaleResultsAsOfNow"] = true
      end

      if (@wait_for_non_stale_results ||
          @wait_for_non_stale_results_as_of_now) &&
         !@wait_for_non_stale_results_timeout.nil?
        json["WaitForNonStaleResultsTimeout"] = @wait_for_non_stale_results_timeout.to_s

      end

      json
    end
  end

  class QueryOperationOptions
    attr_reader :allow_stale, :stale_timeout, :max_ops_per_sec, :retrieve_details

    def initialize(allow_stale = true, stale_timeout = nil, max_ops_per_sec = nil, retrieve_details = false)
      @allow_stale = allow_stale
      @stale_timeout = stale_timeout
      @max_ops_per_sec = max_ops_per_sec
      @retrieve_details = retrieve_details
    end
  end
end
