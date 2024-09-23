# frozen_string_literal: true

module Control
  class CodeUniqueness < Control::Base
    module Options
      extend ActiveSupport::Concern

      REFERENTIAL_MODELS = %w[Route JourneyPattern VehicleJourney TimeTable].freeze
      PROVIDER_MODELS = %w[StopArea Company Line Document Entrance PointOfInterest Shape].freeze
      MODELS = [] + REFERENTIAL_MODELS + PROVIDER_MODELS

      included do
        option :target_model
        option :target_code_space_id
        option :uniqueness_scope

        enumerize :target_model, in: MODELS
        enumerize :uniqueness_scope, in: %w[workgroup workbench provider referential]

        validates :target_model, :target_code_space_id, presence: true

        def provider_target_model?
          target_model.in?(PROVIDER_MODELS)
        end

        def referential_target_model?
          target_model.in?(REFERENTIAL_MODELS)
        end

        validates :uniqueness_scope, inclusion: { in: %w[workgroup workbench provider] }, if: :provider_target_model?
        validates :uniqueness_scope, inclusion: { in: %w[referential] }, if: :referential_target_model?

        def target_code_space
          @target_code_space ||= code_space_scope.find_by(id: target_code_space_id)
        end

        def code_space_scope
          return workgroup.code_spaces unless uniqueness_scope == 'workgroup'

          CodeSpace
        end
      end
    end

    include Options

    class Run < Control::Base::Run
      include Options

      def run
        analysis.duplicates.each do |duplicate|
          create_message(duplicate)
        end
      end

      def create_message(duplicate)
        control_messages.create!(
          message_attributes: {
            code_space: target_code_space.short_name,
            name: duplicate.name, code_value: duplicate.code_value
          },
          criticity: criticity, message_key: :code_uniqueness,
          source_id: duplicate.source_id, source_type: duplicate.source_type
        )
      end

      def analysis
        Analysis.for(uniqueness_scope).new(context, target_model, target_code_space)
      end

      class Analysis
        def self.for(uniqueness_scope)
          const_get(uniqueness_scope.classify)
        end

        class Base
          def initialize(context, target_model, target_code_space)
            @context = context
            @target_model = target_model
            @target_code_space = target_code_space
          end

          attr_accessor :target_model, :context, :target_code_space

          PREFIX_PROVIDERS = {
            stop_area: 'stop_area',
            company: 'line',
            line: 'line',
            document: 'document',
            entrance: 'stop_area',
            point_of_interest: 'shape',
            shape: 'shape'
          }.with_indifferent_access

          def duplicates
            PostgreSQLCursor::Cursor.new(query).map do |attributes|
              Rails.logger.debug "Attributes: #{attributes.inspect}"
              Duplicate.new attributes.merge source_type: source_type
            end
          end

          def model_singular
            @model_singular ||= target_model.underscore
          end

          def source_type
            @source_type ||= if target_model == 'PointOfInterest'
                               'PointOfInterest::Base'
                             else
                               begin
                                 "Chouette::#{target_model}".constantize
                               rescue StandardError
                                 target_model.constantize
                               end.to_s
                             end
          end

          def model_collection
            @model_collection ||= model_singular.pluralize
          end

          def model_table_name
            @model_table_name ||= models.table_name
          end

          def models
            context.send(model_collection)
          end

          def provider_id
            "#{model_collection}.#{PREFIX_PROVIDERS[model_singular]}_provider_id"
          end

          def providers
            "#{PREFIX_PROVIDERS[model_singular]}_providers"
          end

          def where
            <<~SQL
              WHERE (#{codes_table}.resource_type = '#{source_type}')
                AND (#{codes_table}.code_space_id = #{target_code_space.id})
            SQL
          end

          def codes_table
            'codes'
          end

          def name_attribute
            # TODO: we should use Model#name method instead of an SQL approach
            case source_type
            when 'Chouette::VehicleJourney'
              'published_journey_name'
            when 'Chouette::TimeTable'
              'comment'
            else
              'name'
            end
          end

          def query
            <<~SQL
              SELECT * FROM (
                SELECT #{model_table_name}.id, #{model_table_name}.#{name_attribute} as name,
                       #{codes_table}.value AS code_value, #{duplicates_count} AS duplicates_count
                FROM #{model_table_name}
                #{inner_join}
                #{where}
              ) AS with_duplicates_count
              WHERE duplicates_count > 1 AND (id IN (#{models.select(:id).to_sql}))
            SQL
          end

          class Duplicate
            def initialize(attributes)
              attributes.each { |k, v| send "#{k}=", v if respond_to?(k) }
            end

            attr_accessor :name, :source_type, :code_value, :id

            alias source_id id
          end
        end

        class Provider < Base
          def duplicates_count
            <<~SQL
              count(#{model_table_name}.id) OVER(PARTITION BY #{provider_id}, codes.value)
            SQL
          end

          def inner_join
            <<~SQL
              INNER JOIN public.codes ON codes.resource_id = #{model_table_name}.id
            SQL
          end
        end

        class Workbench < Base
          def duplicates_count
            <<~SQL
              count(#{model_table_name}.id) OVER(PARTITION BY workbenches.id, codes.value)
            SQL
          end

          def inner_join
            <<~SQL
              INNER JOIN public.#{providers} ON #{providers}.id = #{provider_id}
              INNER JOIN public.workbenches ON workbenches.id = #{providers}.workbench_id
              INNER JOIN public.codes ON codes.resource_id = #{model_table_name}.id
            SQL
          end
        end

        class Workgroup < Base
          def duplicates_count
            <<~SQL
              count(#{model_table_name}.id) OVER(PARTITION BY workgroups.id, codes.value)
            SQL
          end

          def inner_join
            <<~SQL
              INNER JOIN public.#{providers} ON #{providers}.id = #{provider_id}
              INNER JOIN public.workbenches ON workbenches.id = #{providers}.workbench_id
              INNER JOIN public.workgroups ON workgroups.id = workbenches.workgroup_id
              INNER JOIN public.codes ON codes.resource_id = #{model_table_name}.id
            SQL
          end

          def where
            <<~SQL
              WHERE (codes.resource_type = '#{source_type}')
                AND (codes.code_space_id = #{target_code_space.id})
                AND (workgroups.id = #{context.workgroup.id})
            SQL
          end
        end

        class Referential < Base
          def duplicates_count
            <<~SQL
              count(#{model_table_name}.id) OVER(PARTITION BY referential_codes.value)
            SQL
          end

          def inner_join
            <<~SQL
              INNER JOIN referential_codes ON referential_codes.resource_id = #{model_table_name}.id
            SQL
          end

          def codes_table
            'referential_codes'
          end
        end
      end
    end
  end
end
