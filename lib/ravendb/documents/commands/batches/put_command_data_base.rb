module RavenDB
  class PutCommandDataBase
    attr_reader :id, :name, :change_vector, :document, :type

    def initialize(id, change_vector, document)
      raise ArgumentError, "Document cannot be null" if document.nil?

      @id = id
      @change_vector = change_vector
      @document = document
      @type = :put
      @name = nil
    end

    def serialize(_conventions)
      {
        "Id" => @id,
        "ChangeVector" => @change_vector,
        "Document" => @document,
        "Type" => @type.to_s.upcase
      }
    end
  end
end
