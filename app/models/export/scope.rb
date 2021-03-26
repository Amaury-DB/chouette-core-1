# Selects which models need to be included into an Export
module Export::Scope
  def self.build referential, **options
    Options.new(referential, options).scope
  end

  class Builder
    attr_reader :scope

    def initialize(referential)
      @scope = All.new(referential)
      yield self if block_given?
    end

    def scheduled
      @scope = Scheduled.new(@scope)
      self
    end

    def lines(line_ids)
      @scope = Lines.new(@scope, line_ids)
      self
    end

    def period(date_range)
      @scope = DateRange.new(@scope, date_range)
      self
    end

    def cache
      @scope = Cache.new(@scope)
      self
    end
  end

  class Options
    attr_reader :referential
    attr_accessor :duration, :date_range, :line_ids, :line_provider_ids, :company_ids

    def initialize(referential, attributes = {})
      @referential = referential
      attributes.each { |k, v| send "#{k}=", v }
    end

    def line_ids
      @line_ids || companies_line_ids || line_provider_line_ids
    end

    def line_provider_line_ids
      referential.line_referential.lines.where(line_provider: line_provider_ids).pluck(:id) if line_provider_ids
    end

    def companies_line_ids
      referential.line_referential.lines.where(company: company_ids).pluck(:id) if company_ids
    end

    def builder
      @builder ||= Builder.new(referential) do |builder|
        date_range ? builder.period(date_range) : builder.scheduled
        builder.lines(line_ids) if line_ids

        builder.cache
      end
    end

    delegate :scope, to: :builder
  end

  class All
    attr_reader :referential

    def initialize(referential)
      @referential = referential
    end

    delegate :workgroup, :workbench, :line_referential, :stop_area_referential, :metadatas, to: :referential
    delegate :shape_referential, to: :workgroup

    delegate :companies, to: :line_referential

    delegate :shapes, to: :shape_referential

    delegate :codes, to: :workgroup

    delegate :vehicle_journeys, :vehicle_journey_at_stops, :journey_patterns, :routes, :stop_points, :time_tables, :referential_codes, to: :referential

    def organisations
      workgroup.organisations.where(id: metadatas.joins(referential_source: :organisation).distinct.pluck('organisations.id'))
    end

    def stop_areas
      (workbench || stop_area_referential).stop_areas
    end

    def lines
      (workbench || line_referential).lines
    end
  end

  # By default a Scope uses the current_scope collection.
  class Base < SimpleDelegator
    def initialize(current_scope)
      super current_scope
      @current_scope = current_scope
    end

    def empty?
      vehicle_journeys.empty?
    end

    attr_reader :current_scope

    def lines
      current_scope.lines.distinct.joins(routes: :vehicle_journeys)
        .where("vehicle_journeys.id" => vehicle_journeys)
    end

    def time_tables
      current_scope.time_tables.joins(:vehicle_journeys).where("vehicle_journeys.id" => vehicle_journeys).distinct
    end

    def vehicle_journey_at_stops
      current_scope.vehicle_journey_at_stops.where(vehicle_journey: vehicle_journeys)
    end

    def routes
      current_scope.routes.joins(:vehicle_journeys).distinct
        .where("vehicle_journeys.id" => vehicle_journeys)
    end

    def journey_patterns
      current_scope.journey_patterns.joins(:vehicle_journeys).distinct
        .where("vehicle_journeys.id" => vehicle_journeys)
    end

    def shapes
      current_scope.shapes.where(id: journey_patterns.select(:shape_id))
    end

    def stop_points
      current_scope.stop_points.distinct.joins(route: :vehicle_journeys)
        .where("vehicle_journeys.id" => vehicle_journeys)
    end

    def stop_areas
      stop_areas_in_routes =
        current_scope.stop_areas.joins(routes: :vehicle_journeys).distinct
          .where("vehicle_journeys.id" => vehicle_journeys)

      stop_areas_in_specific_vehicle_journey_at_stops =
        current_scope.stop_areas.joins(:specific_vehicle_journey_at_stops).distinct
          .where("vehicle_journey_at_stops.vehicle_journey_id" => vehicle_journeys)

      Chouette::StopArea.union(stop_areas_in_routes, stop_areas_in_specific_vehicle_journey_at_stops)
    end
  end

  class Scheduled < Base
    def vehicle_journeys
      current_scope.vehicle_journeys.scheduled
    end
  end

  # Selects VehicleJourneys in a Date range, and all other models if they are required
  # to describe these VehicleJourneys
  class DateRange < Base
    attr_reader :date_range

    def initialize(current_scope, date_range)
      super current_scope
      @date_range = date_range
    end

    def vehicle_journeys
      current_scope.vehicle_journeys.with_matching_timetable(date_range)
    end

    def metadatas
      current_scope.metadatas.include_daterange(date_range)
    end
  end

  class Lines < Base
    attr_reader :selected_line_ids

    def initialize(current_scope, selected_line_ids)
      super current_scope
      @selected_line_ids = selected_line_ids
    end

    def vehicle_journeys
      current_scope.vehicle_journeys.with_lines(selected_line_ids)
    end

    def metadatas
      current_scope.metadatas.with_lines(selected_line_ids)
    end
  end

  class Cache < Base
    RESOURCES = %w(
      vehicle_journeys
      vehicle_journey_at_stops
      journey_patterns
      routes
      stop_points
      time_tables
      organisations
      lines
      stop_areas
    ).freeze

    RESOURCES.each do |name|
      define_method(name) do
        value = instance_variable_get("@#{name}")

        value || instance_variable_set("@#{name}", current_scope.send(name))
      end
    end
  end
end
