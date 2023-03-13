module RavenDB
  class GetAttachmentCommand < AttachmentCommand
    def initialize(document_id, name, type, change_vector = nil)
      super(document_id, name, change_vector)

      if @_change_vector.nil? && !AttachmentType.document?(type)
        raise ArgumentError, "Change Vector cannot be null for non-document attachment type"
      end

      @response_type = :attachment
      @_type = type
    end

    def payload
      if payload?
        {"Type" => @_type, "ChangeVector" => @_change_vector}.to_json
      else
        super
      end
    end

    def payload?
      !AttachmentType.document?(@_type)
    end

    def http_method
      if payload?
        Net::HTTP::Post
      else
        Net::HTTP::Get
      end
    end

    def parse_response_raw(response)
      raise DocumentDoesNotExistException if response.is_a?(Net::HTTPNotFound)

      if response.json(false).nil?
        @_last_response = response
      end

      attachment = response.body.force_encoding("ASCII-8BIT")
      content_type = try_get_header("Content-Type")
      hash = try_get_header("Attachment-Hash")
      change_vector = try_get_header("Etag")
      size = try_get_header("Attachment-Size")

      begin
        size = Integer(size || "")
      rescue StandardError
        size = 0
      end

      if change_vector[0] == "\""
        change_vector = change_vector[1..-2]
      end

      {
        stream: attachment,
        attachment_details: {
          content_type:,
          name: @_name,
          hash:,
          size:,
          change_vector:,
          document_id: @_document_id
        }
      }
    end

    def read_request?
      true
    end

    protected

    def try_get_header(header)
      if @_last_response.key?(header)
        @_last_response[header]
      elsif @_last_response.key?(header.downcase)
        @_last_response[header.downcase]
      end
    end
  end
end
