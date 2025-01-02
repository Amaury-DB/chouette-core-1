# frozen_string_literal: true

module Chouette
  class Company < Chouette::ActiveRecord
    has_metadata

    include LineReferentialSupport
    include ObjectidSupport
    include CustomFieldsSupport
    include ReferentSupport
    include CodeSupport
    include Documentable

    has_many :lines, dependent: :nullify
    has_many :contracts, dependent: :nullify

    # validates_format_of :registration_number, :with => %r{\A[0-9A-Za-z_-]+\Z}, :allow_nil => true, :allow_blank => true
    validates_presence_of :name
    validates :registration_number, uniqueness: { scope: :line_provider_id }, allow_blank: true

    # Cf. #8132
    # validates_format_of :url, :with => %r{\Ahttps?:\/\/([\da-z\.-]+)\.([a-z\.]{2,6})([\/\w \.-]*)*\/?\Z}, :allow_nil => true, :allow_blank => true

    scope :by_provider, ->(line_provider) { where(line_provider_id: line_provider.id) }
    scope :by_text, lambda { |text| text.blank? ? all : where('lower(companies.name) LIKE :t or lower(companies.short_name) LIKE :t or lower(companies.objectid) LIKE :t', t: "%#{text.downcase}%") }

    def self.nullable_attributes # rubocop:disable Metrics/MethodLength
      %i[
        address_line_1
        address_line_2
        code
        country_code
        customer_service_contact_email
        customer_service_contact_more
        customer_service_contact_name
        customer_service_contact_phone
        customer_service_contact_url
        default_contact_email
        default_contact_fax
        default_contact_name
        default_contact_operating_department_name
        default_contact_organizational_unit
        default_contact_phone
        default_contact_url
        default_contact_more
        default_language
        house_number
        postcode
        postcode_extension
        private_contact_email
        private_contact_more
        private_contact_name
        private_contact_phone
        private_contact_url
        registration_number
        short_name
        street
        time_zone
        town
      ]
    end

    def has_private_contact?
      %w[private_contact].product(%w[name email phone url more]).any? { |k| send(k.join('_')).present? }
    end

    def has_customer_service_contact?
      %w[customer_service_contact].product(%w[name email phone url more]).any? { |k| send(k.join('_')).present? }
    end

    def full_display_name
      [get_objectid.short_id, name].join(' - ')
    end

    def display_name
      full_display_name.truncate(50)
    end

    def country
      return unless country_code

      ISO3166::Country[country_code]
    end

    def country_name
      return unless country

      country.translations[I18n.locale.to_s] || country.name
    end
  end
end
