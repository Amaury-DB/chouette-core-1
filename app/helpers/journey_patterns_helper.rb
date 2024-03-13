module JourneyPatternsHelper

  def journey_name( journey_pattern)
    unless journey_pattern.name.blank?
      return truncate(journey_pattern.name, :length => 30)
    end

    unless journey_pattern.stop_points.empty?
      return truncate( t('journey_patterns.journey_pattern.from_to',
        :departure => journey_pattern.stop_points.first.stop_area.name,
        :arrival => journey_pattern.stop_points.last.stop_area.name), :length => 30)
    end

    journey_pattern.id.to_s
  end

  def stop_point_ids_label(journey_pattern)
    return journey_pattern.human_attribute_name(:stop_point_ids) if journey_pattern.vehicle_journeys.empty?

    "#{journey_pattern.human_attribute_name(:stop_point_ids)}. #{t('journey_patterns.form.warning', :count => journey_pattern.vehicle_journeys.count)}"
  end
end
