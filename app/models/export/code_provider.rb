# frozen_string_literal: true

module Export
  # Manage all unique codes for a given Export::Scope
  class CodeProvider
    def initialize(export_scope, code_space: nil)
      @export_scope = export_scope
      @code_space = code_space
    end

    attr_reader :export_scope, :code_space

    COLLECTIONS = %w[
      stop_areas point_of_interests vehicle_journeys lines companies entrances contracts
      vehicle_journey_at_stops journey_patterns routes time_tables fare_validities
      routing_constraint_zones networks fare_zones fare_products stop_points shapes line_notices
    ].freeze

    # Returns unique code for the given model (StopArea, etc)
    def code(model)
      return unless model&.id
      collection(self.class.collection_name(model))&.code(model.id)
    end

    def codes(models)
      models.map { |model| code(model) }.compact
    end

    def collection(name)
      if model = instance_variable_get("@#{name}")
        return model
      end

      scope_collection = export_scope.send(name)
      model = Model.new.index(
        Indexer.create(
          scope_collection,
          code_space: code_space,
          code_provider: self
        )
      )
      instance_variable_set("@#{name}", model)
    end

    COLLECTIONS.each do |collection_name|
      define_method(collection_name) do
        collection collection_name
      end
    end

    mattr_reader :collection_names, default: {}

    def self.collection_name(model)
      return nil unless model

      collection_names[model.class] ||=
        begin
          model.model_name.plural
        rescue
          # When the model class is Chouette::StopPoint::Light::StopPoint...
          model.class.name.demodulize.underscore.pluralize
        end
    end

    module Indexer
      class << self
        def create(collection, code_provider:, code_space: nil)
          if code_space && collection.model == Chouette::StopPoint
            StopPoints.new(collection, code_provider: code_provider)
          elsif code_space && collection.model.in?(older_models)
            Older.new(collection, code_space: code_space)
          else
            Default.new(collection, code_space: code_space)
          end
        end

        private

        def older_models
          @older_models ||= [
            Chouette::Route,
            Chouette::JourneyPattern,
            Chouette::VehicleJourney,
            Chouette::TimeTable
          ].to_set
        end
      end

      class Default
        def initialize(collection, options = {})
          @collection = collection

          options.each do |k, v|
            send("#{k}=", v) if respond_to?("#{k}=")
          end
        end

        attr_reader :collection
        attr_accessor :code_space

        def unique_collection
          @unique_collection ||= model_class.where(id: collection.select(:id))
        end

        def model_class
          @model_class ||= collection.model
        end

        delegate :code_table, to: :model_class

        ATTRIBUTES = %w[objectid uuid].freeze
        def default_attribute
          (ATTRIBUTES & model_class.column_names).first
        end

        def index
          if code_space && model_with_codes?
            index_with_codes
          else
            index_without_codes
          end
        end

        def index_without_codes
          collection.pluck(:id, default_attribute).to_h
        end

        def query_with_code
          <<~SQL
          select id_with_default_attribute.id, COALESCE(code, default_attribute) as code
          from (#{unique_collection.select(:id, "#{model_class.table_name}.#{default_attribute}::varchar as default_attribute").to_sql}) id_with_default_attribute
          left join (
            select distinct on (code) id, code from (#{code_query.to_sql}) id_with_code
          ) id_with_uniq_code
          on (id_with_uniq_code.id = id_with_default_attribute.id)
        SQL
        end

        def index_with_codes
          model_class.connection.select_rows(query_with_code).to_h
        end

        def with_code_query
          unique_collection
            .left_joins(:codes)
            .where(code_table[:code_space_id].eq(code_space.id))
            .select(:id, code_value)
            .group(:id)
            .having(having)
        end

        def having
          'count(*) = 1'
        end

        def code_value
          Arel::Nodes::NamedFunction.new(
            'unnest', [
              Arel::Nodes::NamedFunction.new('array_agg', [code_table[:value]])
            ]
          ).as('code')
        end

        def with_registration_number_query
          collection.select(:id, "registration_number as code")
        end

        def code_query
          unless default_code_space? && model_with_registration_number?
            with_code_query
          else
            with_registration_number_query
          end
        end

        def model_with_codes?
          collection.reflect_on_association(:codes).present?
        end

        def model_with_registration_number?
          model_class.column_names.include?("registration_number")
        end

        def default_code_space?
          code_space&.default?
        end
      end

      class StopPoints
        def initialize(stop_points, code_provider:)
          @stop_points = stop_points
          @code_provider = code_provider
        end

        attr_reader :stop_points, :code_provider

        def index
          stop_points.select(:id, :route_id, :position).each_row.map do |attributes|
            route_code = code_provider.routes.code(attributes["route_id"])
            stop_point_code = Code::Value.merge(route_code, attributes["position"], type: 'StopPoint')
            [ attributes["id"], stop_point_code ]
          end.to_h
        end
      end

      # This condition accept several codes in the same Code Space to take one in the method with_code_query
      class Older < Default
        def with_code_query
          code_query = ReferentialCode.order(id: :asc).limit(1)
                                      .where("referential_codes.resource_id = #{model_class.quoted_table_name}.id")
                                      .where(resource_type: model_class.base_class.name, code_space: code_space)
                                      .select(:value)
          unique_collection.joins("JOIN LATERAL (#{code_query.to_sql}) subquery ON true")
                           .select("#{model_class.quoted_table_name}.id", "subquery.value as code")
        end
      end
    end

    class Model
      def initialize
        @codes = {}
      end

      def index(indexer)
        @codes = indexer.index

        self
      end

      def register(model_id, as:)
        @codes[model_id] = as if as
      end

      def code(model_id)
        @codes[model_id] if model_id
      end

      def codes(model_ids)
        model_ids.map { |model_id| code(model_id) }.compact
      end

      def alias(model_id, as:)
        register model_id, as: code(as)
      end
    end

    # Default implementation when a real Export::CodeProvider isn't provided
    #
    # Export::CodeProvider.null.code(..) => nil
    # Export::CodeProvider.null.stop_areas.code(..) => nil
    def self.null
      @null ||= Null.new
    end

    class Null
      def code(_model_or_id); end

      def codes(_models_or_ids)
        []
      end

      def method_missing(name, *arguments)
        return self if name.end_with?('s') && arguments.empty?

        super
      end
    end
  end
end
