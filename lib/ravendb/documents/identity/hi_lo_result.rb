module RavenDB
  class HiLoResult
    attr_accessor :prefix, :low, :high, :last_size, :server_tag, :last_range_at
  end
end
