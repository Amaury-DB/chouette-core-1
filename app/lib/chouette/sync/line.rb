module Chouette::Sync
  module Line
    class Netex < Chouette::Sync::Base

      def initialize(options = {})
        default_options = {
          resource_type: :line,
          resource_id_attribute: :id,
          model_type: :line,
          resource_decorator: Decorator
        }
        options.reverse_merge!(default_options)
        super options
      end

      class Decorator < Chouette::Sync::Updater::ResourceDecorator

        def line_number
          short_name
        end

        def line_desactivated
          status == "inactive"
        end

        TYPE_OF_LINE_SEASONAL = "SEASONAL_LINE_TYPE"
        def line_seasonal
          type_of_line_ref&.ref == TYPE_OF_LINE_SEASONAL
        end

        def line_active_from
          valid_between&.from_date
        end

        def line_active_until
          valid_between&.to_date
        end

        def line_color
          presentation&.colour&.upcase
        end

        def line_text_color
          presentation&.text_colour&.upcase
        end

        def line_company_id
          resolve :company, operator_ref&.ref
        end

        def line_secondary_company_refs
          return [] if additional_operators.blank?
          # Ignore main operator in additional operators
          additional_operators.map(&:ref) - [operator_ref&.ref]
        end

        def line_secondary_company_ids
          resolve :company, line_secondary_company_refs
        end

        def line_network_id
          resolve :network, represented_by_group_ref&.ref
        end

        def model_attributes
          {
            name: name,
            transport_mode: transport_mode,
            transport_submode: transport_submode,
            number: line_number,
            desactivated: line_desactivated,
            seasonal: line_seasonal,
            active_from: line_active_from,
            active_until: line_active_until,
            color: line_color,
            text_color: line_text_color,
            company_id: line_company_id,
            secondary_company_ids: line_secondary_company_ids,
            network_id: line_network_id,
            import_xml: raw_xml
          }
        end

      end

    end

    class Deleter < Chouette::Sync::Deleter

      def existing_models(identifiers = nil)
        super(identifiers).activated
      end

      def delete_all(deleted_scope)
        deleted_scope.desactivate!
      end

    end

  end
end
