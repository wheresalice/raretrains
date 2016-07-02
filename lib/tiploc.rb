class Tiploc
  include Comparable
  attr_accessor :latitude, :longitude, :code

  def initialize(code, lat = nil, lon = nil)
    @code = code
    @latitude = lat
    @longitude = lon
  end

  def <=>(other)
    @code <=> other.code
  end

  def ==(other)
    @code == other.code
  end
end