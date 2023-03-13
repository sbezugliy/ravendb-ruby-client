module RavenDB
  class HttpCacheItem
    attr_accessor :change_vector, :payload, :last_server_update

    # TBD attr_accessor :generation
    # attr_accessor :cache

    def initialize
      self.last_server_update = DateTime.now
    end
  end
end
