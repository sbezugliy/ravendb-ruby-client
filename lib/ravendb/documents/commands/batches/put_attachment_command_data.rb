module RavenDB
  class PutAttachmentCommandData
    def initialize(document_id, name, stream, content_type, change_vector)
      raise ArgumentError, "DocumentId cannot be null" if document_id.nil?
      raise ArgumentError, "Name cannot be null" if name.nil?

      self.id = document_id
      self.name = name
      self.stream = stream
      self.content_type = content_type
      self.change_vector = change_vector
    end

    attr_reader :id, :name, :stream, :change_vector, :content_type, :type

    def serialize(_conventions)
      {
        "Id" => @id,
        "Name" => @name,
        "ContentType" => @content_type,
        "ChangeVector" => @change_vector,
        "Type" => "AttachmentPUT"
      }
    end
  end
end
