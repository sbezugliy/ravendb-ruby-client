require "stringio"
require "constants/documents"
require "database/exceptions"
require "utilities/string_utility"

module RavenDB
  class QueryToken
    QUERY_KEYWORDS = [
      QueryKeyword::AS,
      QueryKeyword::SELECT,
      QueryKeyword::WHERE,
      QueryKeyword::LOAD,
      QueryKeyword::GROUP,
      QueryKeyword::ORDER,
      QueryKeyword::INCLUDE
    ].freeze

    def write_to(writer)
      raise NotImplementedError, "You should implement write_to method"
    end

    protected

    def write_field(writer, field)
      is_keyword = QUERY_KEYWORDS.include?(field)

      writer.append("''") if is_keyword
      writer.append(field)
      writer.append("''") if is_keyword
    end
  end

  class SimpleQueryToken
    def self.instance
      new
    end

    def write_to(writer)
      writer.append(token_text)
    end

    protected

    def token_text
      raise NotImplementedError, "You should implement token_text method"
    end
  end

  class CloseSubclauseToken < SimpleQueryToken
    protected

    def token_text
      ")"
    end
  end

  class DistinctToken < SimpleQueryToken
    protected

    def token_text
      QueryKeyword::DISTINCT
    end
  end

  class FieldsToFetchToken < QueryToken
    attr_reader :fields_to_fetch, :projections

    def self.create(fields_to_fetch, projections = [])
      new(fields_to_fetch, projections)
    end

    def initialize(fields_to_fetch, projections = [])
      super()

      if fields_to_fetch.empty?
        raise ArgumentError,
              "Fields list can't be empty"
      end

      if projections.empty? && projections.size != fields_to_fetch.size
        raise ArgumentError,
              "Length of projections must be the " \
              "same as length of fields to fetch."
      end

      @fields_to_fetch = fields_to_fetch
      @projections = projections
    end

    def write_to(writer)
      @fields_to_fetch.each_index do |index|
        field = @fields_to_fetch[index]
        projection = @projections[index]

        if index > 0
          writer.append(", ")
        end

        write_field(writer, field)

        next if projection.nil? || (projection == field)

        writer.append(" ")
        writer.append(QueryKeyword::AS)
        writer.append(" ")
        writer.append(projection)
      end
    end
  end

  class FromToken < QueryToken
    attr_reader :index_name, :collection_name, :is_dynamic

    WHITE_SPACE_CHARS = [
      " ", "\t", "\r", "\n", "\v"
    ].freeze

    def self.create(index_name = nil, collection_name = nil)
      new(index_name, collection_name)
    end

    def initialize(index_name = nil, collection_name = nil)
      super()

      @collection_name = collection_name
      @index_name = index_name
      @is_dynamic = !collection_name.nil?
    end

    def write_to(writer)
      if @collection_name.nil? && @index_name.nil?
        raise NotSupportedException,
              "Either IndexName or CollectionName must be specified"
      end

      if @is_dynamic
        writer
          .append(QueryKeyword::FROM)
          .append(" ")

        if WHITE_SPACE_CHARS.any? { |char| @collection_name.include?(char) }
          if @collection_name.include?('"')
            raise NotSupportedException,
                  "Collection name cannot contain a quote, but was: #{@collection_name}"
          end

          writer.append('"').append(@collection_name).append('"')
        else
          writer.append(@collection_name)
        end

        return
      end

      writer
        .append(QueryKeyword::FROM)
        .append(" ")
        .append(QueryKeyword::INDEX)
        .append(" '")
        .append(@index_name)
        .append("'")
    end
  end

  class GroupByCountToken < QueryToken
    def self.create(field_name = nil)
      new(field_name)
    end

    def initialize(field_name = nil)
      super()

      @field_name = field_name
    end

    def write_to(writer)
      writer.append("count()")

      if @field_name.nil?
        return
      end

      writer
        .append(" ")
        .append(QueryKeyword::AS)
        .append(" ")
        .append(@field_name)
    end
  end

  class GroupByKeyToken < GroupByCountToken
    def self.create(field_name = nil, projected_name = nil)
      new(field_name, projected_name)
    end

    def initialize(field_name = nil, projected_name = nil)
      super(field_name)

      @projected_name = projected_name
    end

    def write_to(writer)
      write_field(writer, @field_name || "key()")

      if @projected_name.nil? || (@projected_name == @field_name)
        return
      end

      writer
        .append(" ")
        .append(QueryKeyword::AS)
        .append(" ")
        .append(@projected_name)
    end
  end

  class GroupBySumToken < GroupByKeyToken
    def initialize(field_name = nil, projected_name = nil)
      super(field_name, projected_name)

      raise ArgumentError, "Field name can't be null" if field_name.nil?
    end

    def write_to(writer)
      writer
        .append("sum(")
        .append(@field_name)
        .append(")")

      if @projected_name.nil?
        return
      end

      writer
        .append(" ")
        .append(QueryKeyword::AS)
        .append(" ")
        .append(@projected_name)
    end
  end

  class GroupByToken < GroupByCountToken
    def initialize(field_name = nil)
      super(field_name)

      raise ArgumentError, "Field name can't be null" if field_name.nil?
    end

    def write_to(writer)
      write_field(writer, @field_name)
    end
  end

  class IntersectMarkerToken < SimpleQueryToken
    protected

    def token_text
      ","
    end
  end

  class NegateToken < SimpleQueryToken
    protected

    def token_text
      QueryOperator::NOT
    end
  end

  class OpenSubclauseToken < SimpleQueryToken
    protected

    def token_text
      "("
    end
  end

  class OrderByToken < QueryToken
    def self.random
      new("random()")
    end

    def self.score_ascending
      new("score()")
    end

    def self.score_descending
      new("score()", true)
    end

    def self._distance_expression(field_name, latitude_or_shape_wkt_parameter_name, longitude_parameter_name = nil)
      if longitude_parameter_name.nil?
        "spatial.distance(#{field_name}, spatial.wkt($#{latitude_or_shape_wkt_parameter_name}))"
      else
        "spatial.distance(#{field_name}, spatial.point($#{latitude_or_shape_wkt_parameter_name}, $#{longitude_parameter_name}))"
      end
    end

    def self.create_distance_ascending(field_name, latitude_or_shape_wkt_parameter_name, longitude_parameter_name = nil)
      new(_distance_expression(field_name, latitude_or_shape_wkt_parameter_name, longitude_parameter_name))
    end

    def self.create_distance_descending(field_name, latitude_or_shape_wkt_parameter_name, longitude_parameter_name = nil)
      new(_distance_expression(field_name, latitude_or_shape_wkt_parameter_name, longitude_parameter_name), true)
    end

    def self.create_random(seed)
      raise ArgumentError, "Seed can't be null" if seed.nil?

      new("random('#{seed.gsub("'", "''")}')")
    end

    def self.create_ascending(field_name, ordering = OrderingType::STRING)
      new(field_name, false, ordering)
    end

    def self.create_descending(field_name, ordering = OrderingType::STRING)
      new(field_name, true, ordering)
    end

    def initialize(field_name, descending = false, ordering = OrderingType::STRING)
      super()

      @field_name = field_name
      @descending = descending
      @ordering = ordering
    end

    def write_to(writer)
      write_field(writer, @field_name)

      if !@ordering.nil? && (@ordering != OrderingType::STRING)
        writer
          .append(" ")
          .append(QueryKeyword::AS)
          .append(" ")
          .append(@ordering)
      end

      if @descending
        writer
          .append(" ")
          .append(QueryKeyword::DESC)
      end
    end
  end

  class QueryOperatorToken < QueryToken
    def self.and
      new(QueryOperator::AND)
    end

    def self.or
      new(QueryOperator::OR)
    end

    def initialize(query_operator)
      @query_operator = query_operator
    end

    def write_to(writer)
      writer.append(@query_operator)
    end
  end

  class ShapeToken < QueryToken
    def self.circle(radius_parameter_name, latitute_parameter_name, longitude_parameter_name, radius_units = nil)
      expression = if radius_units.nil?
                     "spatial.circle($#{radius_parameter_name}, $#{latitute_parameter_name}, $#{longitude_parameter_name})"
                   else
                     "spatial.circle($#{radius_parameter_name}, $#{latitute_parameter_name}, $#{longitude_parameter_name}, '#{radius_units}')"
                   end

      new(expression)
    end

    def self.wkt(shape_wkt_parameter_name)
      new("spatial.wkt($#{shape_wkt_parameter_name})")
    end

    def initialize(shape)
      @shape = shape
    end

    def write_to(writer)
      writer.append(@shape)
    end
  end

  class TrueToken < SimpleQueryToken
    protected

    def token_text
      true.to_s
    end
  end

  class WhereToken < QueryToken
    attr_accessor :boost, :fuzzy, :proximity
    attr_reader :field_name, :where_operator, :search_operator,
                :parameter_name, :from_parameter_name, :to_parameter_name,
                :exact, :where_shape, :distance_error_pct

    def self.equals(field_name, parameter_name, exact = false)
      new(
        field_name:,
        parameter_name:,
        exact:,
        where_operator: WhereOperator::EQUALS
      )
    end

    def self.not_equals(field_name, parameter_name, exact = false)
      new(
        field_name:,
        parameter_name:,
        exact:,
        where_operator: WhereOperator::NOT_EQUALS
      )
    end

    def self.starts_with(field_name, parameter_name)
      new(
        field_name:,
        parameter_name:,
        where_operator: WhereOperator::STARTS_WITH
      )
    end

    def self.ends_with(field_name, parameter_name)
      new(
        field_name:,
        parameter_name:,
        where_operator: WhereOperator::ENDS_WITH
      )
    end

    def self.greater_than(field_name, parameter_name, exact = false)
      new(
        field_name:,
        parameter_name:,
        exact:,
        where_operator: WhereOperator::GREATER_THAN
      )
    end

    def self.greater_than_or_equal(field_name, parameter_name, exact = false)
      new(
        field_name:,
        parameter_name:,
        exact:,
        where_operator: WhereOperator::GREATER_THAN_OR_EQUAL
      )
    end

    def self.less_than(field_name, parameter_name, exact = false)
      new(
        field_name:,
        parameter_name:,
        exact:,
        where_operator: WhereOperator::LESS_THAN
      )
    end

    def self.less_than_or_equal(field_name, parameter_name, exact = false)
      new(
        field_name:,
        parameter_name:,
        exact:,
        where_operator: WhereOperator::LESS_THAN_OR_EQUAL
      )
    end

    def self.in(field_name, parameter_name, exact = false)
      new(
        field_name:,
        parameter_name:,
        exact:,
        where_operator: WhereOperator::IN
      )
    end

    def self.all_in(field_name, parameter_name)
      new(
        field_name:,
        parameter_name:,
        where_operator: WhereOperator::ALL_IN
      )
    end

    def self.between(field_name, from_parameter_name, to_parameter_name, exact = false)
      new(
        field_name:,
        from_parameter_name:,
        to_parameter_name:,
        exact:,
        where_operator: WhereOperator::BETWEEN
      )
    end

    def self.search(field_name, parameter_name, op = SearchOperator::AND)
      new(
        field_name:,
        parameter_name:,
        search_operator: op,
        where_operator: WhereOperator::SEARCH
      )
    end

    def self.lucene(field_name, parameter_name)
      new(
        field_name:,
        parameter_name:,
        where_operator: WhereOperator::LUCENE
      )
    end

    def self.exists(field_name)
      new(
        field_name:,
        where_operator: WhereOperator::EXISTS
      )
    end

    def self.within(field_name, shape, distance_error_pct)
      new(
        field_name:,
        where_shape: shape,
        distance_error_pct:,
        where_operator: WhereOperator::WITHIN
      )
    end

    def self.contains(field_name, shape, distance_error_pct)
      new(
        field_name:,
        where_shape: shape,
        distance_error_pct:,
        where_operator: WhereOperator::CONTAINS
      )
    end

    def self.disjoint(field_name, shape, distance_error_pct)
      new(
        field_name:,
        where_shape: shape,
        distance_error_pct:,
        where_operator: WhereOperator::DISJOINT
      )
    end

    def self.intersects(field_name, shape, distance_error_pct)
      new(
        field_name:,
        where_shape: shape,
        distance_error_pct:,
        where_operator: WhereOperator::INTERSECTS
      )
    end

    def self.regex(field_name, parameter)
      new(
        field_name:,
        where_operator: WhereOperator::REGEX,
        parameter_name: parameter
      )
    end

    def initialize(where_options)
      super()

      @boost = nil
      @fuzzy = nil
      @proximity = nil
      @field_name = where_options[:field_name]
      @where_operator = where_options[:where_operator]
      @search_operator = where_options[:search_operator]
      @parameter_name = where_options[:parameter_name]
      @from_parameter_name = where_options[:from_parameter_name]
      @to_parameter_name = where_options[:to_parameter_name]
      @exact = where_options[:exact] || false
      @distance_error_pct = where_options[:distance_error_pct]
      @where_shape = where_options[:where_shape]
    end

    def write_to(writer)
      unless @boost.nil?
        writer.append("boost(")
      end

      unless @fuzzy.nil?
        writer.append("fuzzy(")
      end

      unless @proximity.nil?
        writer.append("proximity(")
      end

      if @exact
        writer.append("exact(")
      end

      case @where_operator
      when WhereOperator::SEARCH,
             WhereOperator::LUCENE,
             WhereOperator::STARTS_WITH,
             WhereOperator::ENDS_WITH,
             WhereOperator::EXISTS,
             WhereOperator::WITHIN,
             WhereOperator::CONTAINS,
             WhereOperator::DISJOINT,
             WhereOperator::INTERSECTS,
             WhereOperator::REGEX
        writer
          .append(@where_operator)
          .append("(")
      end

      write_field(writer, @field_name)

      case @where_operator
      when WhereOperator::IN
        writer
          .append(" ")
          .append(QueryKeyword::IN)
          .append(" ($")
          .append(@parameter_name)
          .append(")")
      when WhereOperator::ALL_IN
        writer
          .append(" ")
          .append(QueryKeyword::ALL)
          .append(" ")
          .append(QueryKeyword::IN)
          .append(" ($")
          .append(@parameter_name)
          .append(")")
      when WhereOperator::BETWEEN
        writer
          .append(" ")
          .append(QueryKeyword::BETWEEN)
          .append(" $")
          .append(@from_parameter_name)
          .append(" ")
          .append(QueryOperator::AND)
          .append(" $")
          .append(@to_parameter_name)
      when WhereOperator::EQUALS
        writer
          .append(" = $")
          .append(@parameter_name)
      when WhereOperator::NOT_EQUALS
        writer
          .append(" != $")
          .append(@parameter_name)
      when WhereOperator::GREATER_THAN
        writer
          .append(" > $")
          .append(@parameter_name)
      when WhereOperator::GREATER_THAN_OR_EQUAL
        writer
          .append(" >= $")
          .append(@parameter_name)
      when WhereOperator::LESS_THAN
        writer
          .append(" < $")
          .append(@parameter_name)
      when WhereOperator::LESS_THAN_OR_EQUAL
        writer
          .append(" <= $")
          .append(@parameter_name)
      when WhereOperator::SEARCH
        writer
          .append(", $")
          .append(@parameter_name)

        if @search_operator == SearchOperator::AND
          writer
            .append(", ")
            .append(@search_operator)
        end

        writer.append(")")
      when WhereOperator::LUCENE,
             WhereOperator::STARTS_WITH,
             WhereOperator::ENDS_WITH
        writer
          .append(", $")
          .append(@parameter_name)
          .append(")")
      when WhereOperator::EXISTS
        writer
          .append(")")
      when WhereOperator::WITHIN,
             WhereOperator::CONTAINS,
             WhereOperator::DISJOINT,
             WhereOperator::INTERSECTS
        writer
          .append(", ")

        @where_shape.write_to(writer)

        if (@distance_error_pct.to_f - SpatialConstants::DEFAULT_DISTANCE_ERROR_PCT).abs > Float::EPSILON
          writer.append(", ")
          writer.append(@distance_error_pct.to_s)
        end

        writer
          .append(")")
      when WhereOperator::REGEX
        writer
          .append(", $")
          .append(@parameter_name)
          .append(")")
      else
        raise IndexError, "Invalid where operator provided"
      end

      if @exact
        writer.append(")")
      end

      unless @proximity.nil?
        writer
          .append(", ")
          .append(@proximity.to_s)
          .append(")")
      end

      unless @fuzzy.nil?
        writer
          .append(", ")
          .append(@fuzzy.to_s)
          .append(")")
      end

      unless @boost.nil?
        writer
          .append(", ")
          .append(@boost.to_s)
          .append(")")
      end
    end
  end
end
