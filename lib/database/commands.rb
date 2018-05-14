require "set"
require "uri"
require "json"
require "date"
require "net/http"
require "utilities/json"
require "utilities/mapper"
require "database/exceptions"
require "documents/query/index_query"
require "documents/indexes"
require "requests/request_helpers"
require "utilities/type_utilities"
require "constants/documents"

module RavenDB
  class RavenCommand
    ETAG_HEADER = "ETag".freeze

    attr_accessor :result
    attr_accessor :status_code
    attr_reader :response_type
    attr_reader :failed_nodes

    def initialize(end_point, method = Net::HTTP::Get::METHOD, params = {}, payload = nil, headers = {})
      @end_point = end_point || ""
      @method = method
      @params = params
      @payload = payload
      @headers = headers
      @failed_nodes = Set.new([])
      @_last_response = nil
      @mapper = JsonObjectMapper.new
      @response_type = :object
    end

    def can_cache?
      false
    end

    def server_response
      @_last_response
    end

    def was_failed?
      !@failed_nodes.empty?
    end

    def add_failed_node(node)
      assert_node(node)
      @failed_nodes.add(node)
    end

    def was_failed_with_node?(node)
      assert_node(node)
      @failed_nodes.include?(node)
    end

    def create_request(server_node)
      raise NotImplementedError, "You should implement create_request method"
    end

    def to_request_options
      end_point = @end_point

      unless @params.empty?
        encoded_params = URI.encode_www_form(@params)
        end_point = "#{end_point}?#{encoded_params}"
      end

      request_ctor = Object.const_get("Net::HTTP::#{@method.capitalize}")
      request = request_ctor.new(end_point)

      if !@payload.nil? && !@payload.empty?
        begin
          request.body = JSON.generate(@payload)
        rescue JSON::GeneratorError
          raise "Invalid payload specified. Can be JSON object only"
        end
        @headers["Content-Type"] = "application/json"
      end

      unless @headers.empty?
        @headers.each do |header, value|
          request.add_field(header, value)
        end
      end

      request
    end

    def set_response(response)
      @_last_response = response

      return unless @_last_response

      ExceptionsFactory.raise_from(response)
      response.json
    end

    def read_request?
      raise NotImplementedError, "You should implement read_request? method"
    end

    def send_request(http_client, request)
      RavenDB.logger.debug("#{self.class} send_request #{request.method} #{request.path} body: #{request.body} headers: #{request.to_hash}")
      response = http_client.request(request)
      RavenDB.logger.warn("#{self.class} send_request response: #{response.code} #{response.message}")
      if response.code.to_i >= 400
        RavenDB.logger.warn("#{self.class} send_request: #{response.body}")
      end
      response
    end

    def on_response_failure(_response)
    end

    def process_response(cache, response, url)
      entity = response

      if entity.nil?
        return :automatic
      end

      if response_type == :empty || response.is_a?(Net::HTTPNoContent)
        return :automatic
      end

      if response_type == :object
        content_length = entity.content_length
        if content_length == 0
          return :automatic
        end

        # we intentionally don't dispose the reader here, we'll be using it
        # in the command, any associated memory will be released on context reset
        json = JSON.parse(entity.body)
        unless cache.nil? # precaution
          cache_response(cache, url, response, json)
        end

        parse_response(json, from_cache: false)
        return :automatic
      else
        parse_response_raw(response, entity.getContent)
      end

      :automatic
    end

    def cache_response(cache, url, response, response_json)
      unless can_cache?
        return
      end

      change_vector = response[ETAG_HEADER]
      return if change_vector.nil?

      cache.set(url, change_vector, response_json)
    end

    protected

    def assert_node(node)
      raise ArgumentError, "Argument \"node\" should be an instance of ServerNode" unless node.is_a? ServerNode
    end

    def raise_invalid_response!
      raise ErrorResponseException, "Invalid server response"
    end

    def add_params(param_or_params, value)
      new_params = param_or_params

      unless new_params.is_a?(Hash)
        new_params = {}
        new_params[param_or_params] = value
      end

      @params = @params.merge(new_params)
    end

    def remove_params(param_or_params, *other_params)
      remove = param_or_params

      unless remove.is_a?(Array)
        remove = [remove]
      end

      unless other_params.empty?
        remove = remove.concat(other_params)
      end

      remove.each { |param| @params.delete(param) }
    end
  end

  class QueryBasedCommand < RavenCommand
    def initialize(method, query, options = nil)
      super("", method)
      @query = query
      @options = options || QueryOperationOptions.new
    end

    def create_request(server_node)
      assert_node(server_node)
      query = @query
      options = @options

      unless query.is_a?(IndexQuery)
        raise "Query must be instance of IndexQuery class"
      end

      unless options.is_a?(QueryOperationOptions)
        raise "Options must be instance of QueryOperationOptions class"
      end

      @params = {
        "allowStale" => options.allow_stale,
        "details" => options.retrieve_details,
        "maxOpsPerSec" => options.max_ops_per_sec
      }

      @end_point = "/databases/#{server_node.database}/queries"

      return unless options.allow_stale && options.stale_timeout

      add_params("staleTimeout", options.stale_timeout)
    end
  end

  class RavenCommandData
    def initialize(id, change_vector)
      @id = id
      @change_vector = change_vector
      @type = nil
    end

    def document_id
      @id
    end

    def to_json
      {
        "Type" => @type,
        "Id" => @id,
        "ChangeVector" => @change_vector
      }
    end
  end
end

require_relative "./commands/batch"
require_relative "./commands/databases"
require_relative "./commands/documents"
require_relative "./commands/indexes"
require_relative "./commands/queries"
require_relative "./commands/hilo"
require_relative "./commands/attachments"
