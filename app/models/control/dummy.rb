module Control
  class Dummy < Control::Base
    option :expected_result
    enumerize :expected_result, in: %w[warning error failed], default: 'warning'

    option :target_model
    enumerize :target_model, in: %w[
      Line
      LineGroup
      LineNotice
      Company
      Network
      StopArea
      StopAreaGroup
      Entrance
      ConnectionLink
      Shape
      PointOfInterest
      ServiceFacilitySet
      AccessibilityAssessment
      Fare::Zone
      LineRoutingConstraintZone
      Document
      Contract
      Route
      JourneyPattern
      VehicleJourney
      TimeTable
      ServiceCount
    ], default: 'Line'

    class Run < Control::Base::Run
      option :target_model

      def run
        raise 'Raise error as expected' if options[:expected_result] == 'fail'

        models.find_each do |model|
          control_messages.create(
            message_attributes: { name: model.try(:name) || model.try(:published_journey_name) || model.try(:comment) },
            message_key: :dummy,
            criticity: criticity,
            source: model
          )
        end
      end

      def model_collection
        @model_collection ||= target_model.underscore.gsub('/', '_').pluralize
      end

      def models
        @models ||= context.send(model_collection)
      end
    end
  end
end
