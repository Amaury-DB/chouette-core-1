# frozen_string_literal: true

module Chouette
  class Line < Chouette::ActiveRecord
    before_validation :update_unpermitted_blank_values

    has_metadata
    include LineReferentialSupport
    include ObjectidSupport
    include TransportModeEnumerations
    enumerize_transport_submode

    enumerize :mobility_impaired_accessibility, in: %i[unknown yes no partial], default: :unknown
    enumerize :wheelchair_accessibility, in: %i[unknown yes no partial], default: :unknown
    enumerize :step_free_accessibility, in: %i[unknown yes no partial], default: :unknown
    enumerize :escalator_free_accessibility, in: %i[unknown yes no partial], default: :unknown
    enumerize :lift_free_accessibility, in: %i[unknown yes no partial], default: :unknown
    enumerize :audible_signals_availability, in: %i[unknown yes no partial], default: :unknown
    enumerize :visual_signs_availability, in: %i[unknown yes no partial], default: :unknown
    enumerize :flexible_line_type, in: %i[
    corridor_service
    main_route_with_flexible_ends
    flexible_areas_only
    hail_and_ride_sections
    fixed_stop_area_wide
    free_area_area_wide
    mixed_flexible
    mixed_flexible_and_fixed
    fixed
    other
  ], scope: true

    include ColorSupport
    include CodeSupport
    include ReferentSupport
    include Documentable

    open_color_attribute
    open_color_attribute :text_color

    belongs_to :company, optional: true # CHOUETTE-3247 failing specs
    belongs_to :network, optional: true # CHOUETTE-3247 failing specs
    belongs_to :booking_arrangement, optional: true

    # this 'light' relation prevents the custom fields loading
    belongs_to :company_light, lambda { # CHOUETTE-3247 failing specs
                                 select(:id, :name, :line_referential_id, :objectid)
                               }, class_name: 'Chouette::Company', foreign_key: :company_id, optional: true

    belongs_to_array_in_many :line_routing_constraint_zones, class_name: 'LineRoutingConstraintZone', array_name: :lines
    belongs_to_array_in_many :contracts, class_name: '::Contract', array_name: :lines

    has_array_of :secondary_companies, class_name: 'Chouette::Company'

    has_many :routes
    has_many :journey_patterns, through: :routes
    has_many :vehicle_journeys, through: :journey_patterns
    has_many :routing_constraint_zones, through: :routes
    has_many :time_tables, -> { distinct }, through: :vehicle_journeys

    has_many :line_notice_memberships, inverse_of: :line, dependent: :destroy
    has_many :line_notices, through: :line_notice_memberships, inverse_of: :lines
    has_many :group_members, class_name: 'LineGroup::Member', dependent: :destroy, inverse_of: :line
    has_many :groups, through: :group_members, inverse_of: :lines

    has_many :footnotes, inverse_of: :line, validate: true
    accepts_nested_attributes_for :footnotes, reject_if: :all_blank, allow_destroy: true

    validates :name, presence: true
    validate :transport_mode_and_submode_match
    validate :active_from_less_than_active_until
    validates :registration_number, uniqueness: { scope: :line_provider_id }, allow_blank: true

    scope :by_text, lambda { |text|
                      text.blank? ? all : where('lower(lines.name) LIKE :t or lower(lines.published_name) LIKE :t or lower(lines.objectid) LIKE :t or lower(lines.comment) LIKE :t or lower(lines.number) LIKE :t', t: "%#{text.downcase}%")
                    }

    scope :by_name, lambda { |name|
      joins('LEFT OUTER JOIN public.companies by_name_companies ON by_name_companies.id = lines.company_id')
        .where('
          lines.number LIKE :q
          OR unaccent(lines.name) ILIKE unaccent(:q)
          OR unaccent(by_name_companies.name) ILIKE unaccent(:q)',
               q: "%#{sanitize_sql_like(name)}%")
    }

    scope :for_workbench, lambda { |workbench|
      where(line_referential_id: workbench.line_referential_id)
    }

    scope :notifiable, lambda { |workbench|
      where(id: workbench.notification_rules.pluck(:line_id))
    }

    scope :active, lambda { |*args|
      on_date = args.first || Time.zone.now
      activated.active_from(on_date).active_until(on_date)
    }

    scope :by_provider, ->(line_provider) { where(line_provider_id: line_provider.id) }

    scope :deactivated, -> { where(deactivated: true) }
    scope :activated, -> { where(deactivated: [nil, false]) }
    scope :active_from, ->(from_date) { where('active_from IS NULL OR active_from <= ?', from_date.to_date) }
    scope :active_until, ->(until_date) { where('active_until IS NULL OR active_until >= ?', until_date.to_date) }

    scope :active_after, ->(date) { activated.where('active_until IS NULL OR active_until >= ?', date) }
    scope :active_before, ->(date) { activated.where('active_from IS NULL OR active_from < ?', date) }
    scope :active_between, ->(from, to) { active_after(from).active_before(to) }
    scope :not_active_after, lambda { |date|
                               where('deactivated = ? OR (active_until IS NOT NULL AND active_until < ?)', true, date)
                             }
    scope :not_active_before, lambda { |date|
                                where('deactivated = ? OR (active_from IS NOT NULL AND active_from >= ?)', true, date)
                              }
    scope :not_active_between, lambda { |from, to|
                                 where('deactivated = ? OR (active_from IS NOT NULL AND active_from >= ?) OR (active_until IS NOT NULL AND active_until < ?)', true, to, from)
                               }

    def self.nullable_attributes
      %i[registration_number published_name number comment url color text_color]
    end

    def chouette_transport_mode
      submode = transport_submode == 'undefined' ? nil : transport_submode&.underscore
      Chouette::TransportMode.new(transport_mode&.underscore, submode)
    end

    def chouette_transport_mode=(transport_mode)
      self.transport_mode = transport_mode.camelize_mode
      self.transport_submode = transport_mode.camelize_sub_mode
    end

    def commercial_stop_areas
      Chouette::StopArea.joins(children: [stop_points: [route: :line]]).where(lines: { id: id }).distinct
    end

    def stop_areas
      Chouette::StopArea.joins(stop_points: [route: :line]).where(lines: { id: id })
    end

    def stop_areas_last_parents
      Chouette::StopArea.joins(stop_points: [route: :line]).where(lines: { id: id }).collect(&:root).flatten.uniq
    end

    def full_display_name
      [get_objectid.short_id, number, name, company_light.try(:name)].compact.join(' - ')
    end

    def display_name
      full_display_name.truncate(70)
    end

    def company_ids
      ([company_id] + Array(secondary_company_ids)).compact
    end

    def companies
      line_referential.companies.where(id: company_ids)
    end

    def active_from_less_than_active_until
      return unless active_from && active_until

      return unless active_from > active_until

      errors.add(:active_until, :active_from_less_than_active_until)
    end

    def active?(on_date = Time.zone.now)
      on_date = on_date.to_date

      return false if deactivated
      return false if active_from && active_from > on_date
      return false if active_until && active_until < on_date

      true
    end

    def always_active_on_period?(from, to)
      return false if deactivated

      return false if active_from && active_from > from
      return false if active_until && active_until < to

      true
    end

    def activated
      !deactivated
    end
    alias activated? activated

    def desactivated
      deactivated
    end

    def desactivated=(value)
      self.deactivated = value
    end

    def activated=(val)
      bool = !ActiveModel::Type::Boolean.new.cast(val)
      self.deactivated = bool
    end

    def status
      activated? ? :activated : :deactivated
    end

    def self.statuses
      %i[activated deactivated]
    end

    def activate
      update deactivated: false
    end

    def deactivate!
      update deactivated: true
    end

    def self.desactivate!
      update_all deactivated: true
    end

    def code
      get_objectid.try(:local_id)
    end

    def flexible_service?
      flexible_line_type.present?
    end

    private

    def update_unpermitted_blank_values
      self.transport_submode = :undefined if transport_submode.blank?
    end
  end
end
