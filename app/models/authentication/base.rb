# frozen_string_literal: true

module Authentication
  class Base < ApplicationModel
    self.table_name = 'authentications'

    extend Enumerize
    include NilIfBlank

    enumerize :type, in: %w[Authentication::Saml]
    belongs_to :organisation, inverse_of: :authentication # CHOUETTE-3247 required: true

    validates :type, :name, presence: true
    validates :name, uniqueness: { scope: :organisation_id }

    def self.nullable_attributes
      %i[
        subtype
      ]
    end

    def subtype_data
      return nil unless subtype

      @subtype_data ||= self.class::Subtype.const_get(subtype.classify.to_sym)
    end

    def sign_in_url(_helper)
      raise NotImplementedError
    end
  end
end
