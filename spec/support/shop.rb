class Shop
  attr_accessor :id, :latitude, :longitude

  def initialize(id = nil, latitude = nil, longitude = nil)
    @id = id
    @latitude = latitude
    @longitude = longitude
  end
end
