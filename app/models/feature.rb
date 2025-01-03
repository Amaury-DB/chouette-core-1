# frozen_string_literal: true

# List conditionnal features
class Feature
  def self.base
    %w[
      consolidated_offers
      core_control_blocks
      create_opposite_routes
      create_referential_from_merge
      detailed_calendars
      journey_length_in_vehicle_journeys
      long_distance_routes
      purge_merged_data
      route_stop_areas_all_types
      routing_constraint_zone_exclusion_in_vehicle_journey
      stop_area_localized_names
      stop_area_waiting_time
      vehicle_journeys_return_route
      stop_area_routing_constraints
      stop_area_connection_links
      import_netex_store_xml
    ]
  end

  mattr_accessor :additionals, default: Chouette::Config.additional_features

  def self.all
    @all ||= (base + additionals).uniq
  end
end
