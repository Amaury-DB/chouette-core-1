module Types
  class StopAreaType < Types::BaseObject
    description "A Chouette StopArea"

    field :objectid, String, null: false
    field :name, String, null: true
    field :area_type, String, null:true
    field :registration_number, String, null:true
    field :country, String, null:true
    field :street_name, String, null:true
    field :zip_code, String, null:true
    field :city_name, String, null:true
    field :postal_region, String, null:true
    field :url, String, null:true
    field :time_zone, String, null:true
    field :kind, String, null:true
    field :comment, String, null:true
    field :status, String, null:true

    field :is_referent, Boolean, null:true

    field :waiting_time, Integer, null:true

    field :longitude, Float, null:true
    field :latitude, Float, null:true

    field :localized_names, Types::PrettyJSON, null:true

    field :created_at, GraphQL::Types::ISO8601DateTime, null:true
    field :updated_at, GraphQL::Types::ISO8601DateTime, null:true
    field :confirmed_at, GraphQL::Types::ISO8601DateTime, null:true
    field :deleted_at, GraphQL::Types::ISO8601DateTime, null:true

    field :referent, Types::StopAreaType, null: true
    def referent
      LazyLoading::StopRelation.new(context, object.referent_id) if object.referent_id
    end

    field :parent, Types::StopAreaType, null: true
    def parent
      LazyLoading::StopRelation.new(context, object.parent_id) if object.parent_id
    end

    field :children, Types::StopAreaType.connection_type, null: true
    def children
      LazyLoading::Children.new(context, object.id)
    end

    field :lines, Types::LineType.connection_type, null: true,
      description: "The StopArea's Lines"
    def lines
      LazyLoading::Lines.new(context, object.id)
    end
  end
end