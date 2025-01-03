class CustomFieldGroup < ApplicationModel
  belongs_to :workgroup # CHOUETTE-3247 optional: false

  has_many :custom_fields, -> { order(position: :asc) }, class_name: "CustomField", dependent: :nullify, foreign_key: "custom_field_group_id", inverse_of: :custom_field_group

  validates :resource_type, presence: true
  acts_as_list scope: :workgroup
end
