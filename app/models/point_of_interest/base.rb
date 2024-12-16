# frozen_string_literal: true

module PointOfInterest
  class Base < ApplicationModel
    include ShapeReferentialSupport
    include NilIfBlank
    include CodeSupport
    include RawImportSupport

    self.table_name = 'point_of_interests'

    belongs_to :shape_referential # CHOUETTE-3247 required: true
    belongs_to :shape_provider # CHOUETTE-3247 required: true
    belongs_to :point_of_interest_category, class_name: 'PointOfInterest::Category', # CHOUETTE-3247 optional: false + required: true (!)
                                            inverse_of: :point_of_interests

    has_many :codes, as: :resource, dependent: :delete_all
    has_many :point_of_interest_hours, dependent: :delete_all, class_name: 'PointOfInterest::Hour',
                                       foreign_key: :point_of_interest_id
    accepts_nested_attributes_for :point_of_interest_hours, allow_destroy: true, reject_if: :all_blank

    validates_associated :point_of_interest_hours
    validates :name, presence: true

    before_validation :position_from_input

    # rubocop:disable Naming/VariableNumber
    scope :without_address, -> { where country: nil, city_name: nil, zip_code: nil, address_line_1: nil }
    scope :with_position, -> { where.not position: nil }
    scope :with_category, ->(point_of_interest_category) { where(point_of_interest_category: point_of_interest_category) }

    def self.nullable_attributes
      %i[
        address_line_1
        zip_code
        city_name
        country
        postal_region
      ]
    end
    # rubocop:enable Naming/VariableNumber

    def position_from_input
      PositionInput.new(@position_input).change(self)
    end

    attr_writer :position_input

    def self.model_name
      ActiveModel::Name.new self, nil, 'PointOfInterest'
    end

    def position_input
      @position_input || ("#{position.y} #{position.x}" if position)
    end

    def longitude
      position&.x
    end

    def latitude
      position&.y
    end

    def address=(address)
      self.country = address.country_name
      self.address_line_1 = address.house_number_and_street_name
      self.zip_code = address.post_code
      self.city_name = address.city_name
    end
  end
end
