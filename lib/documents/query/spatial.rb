require "constants/documents"
require "documents/query/query_tokens"

module RavenDB
  class SpatialCriteria
    def self.relates_to_shape(shape_wkt, relation, dist_error_percent = SpatialConstants::DEFAULT_DISTANCE_ERROR_PCT)
      WktCriteria.new(shape_wkt, relation, dist_error_percent)
    end

    def self.intersects(shape_wkt, dist_error_percent = SpatialConstants::DEFAULT_DISTANCE_ERROR_PCT)
      relates_to_shape(shape_wkt, SpatialRelation::INTERSECTS, dist_error_percent)
    end

    def self.contains(shape_wkt, dist_error_percent = SpatialConstants::DEFAULT_DISTANCE_ERROR_PCT)
      relates_to_shape(shape_wkt, SpatialRelation::CONTAINS, dist_error_percent)
    end

    def self.disjoint(shape_wkt, dist_error_percent = SpatialConstants::DEFAULT_DISTANCE_ERROR_PCT)
      relates_to_shape(shape_wkt, SpatialRelation::DISJOINT, dist_error_percent)
    end

    def self.within(shape_wkt, dist_error_percent = SpatialConstants::DEFAULT_DISTANCE_ERROR_PCT)
      relates_to_shape(shape_wkt, SpatialRelation::WITHIN, dist_error_percent)
    end

    def self.within_radius(radius, latitude, longitude, radius_units = nil, dist_error_percent = SpatialConstants::DEFAULT_DISTANCE_ERROR_PCT)
      CircleCriteria.new(radius, latitude, longitude, radius_units, SpatialRelation::WITHIN, dist_error_percent)
    end

    def initialize(relation, dist_error_percent)
      @relation = relation
      @distance_error_pct = dist_error_percent
    end

    def get_shape_token(&)
      raise NotImplementedError, "You should implement get_shape_token method"
    end

    def to_query_token(field_name, &)
      relation_token = nil
      shape_token = get_shape_token(&)

      case @relation
      when SpatialRelation::INTERSECTS
        relation_token = WhereToken.intersects(field_name, shape_token, @distance_error_pct)
      when SpatialRelation::CONTAINS
        relation_token = WhereToken.contains(field_name, shape_token, @distance_error_pct)
      when SpatialRelation::WITHIN
        relation_token = WhereToken.within(field_name, shape_token, @distance_error_pct)
      when SpatialRelation::DISJOINT
        relation_token = WhereToken.disjoint(field_name, shape_token, @distance_error_pct)
      end

      relation_token
    end
  end

  class CircleCriteria < SpatialCriteria
    def initialize(radius, latitude, longitude, radius_units, relation, dist_error_percent)
      super(relation, dist_error_percent)

      @radius = radius
      @latitude = latitude
      @longitude = longitude
      @radius_units = radius_units || SpatialUnits::KILOMETERS
    end

    def get_shape_token(&)
      ShapeToken.circle(
        yield(@radius),
        yield(@latitude),
        yield(@longitude),
        @radius_units
      )
    end
  end

  class WktCriteria < SpatialCriteria
    def initialize(shape_wkt, relation, distance_error_pct)
      super(relation, distance_error_pct)

      @shape_wkt = shape_wkt
    end

    def get_shape_token(&)
      ShapeToken.wkt(yield(@shape_wkt))
    end
  end
end
