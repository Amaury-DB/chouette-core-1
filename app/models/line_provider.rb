class LineProvider < ApplicationModel

  belongs_to :line_referential, required: true
  belongs_to :workbench, required: true
  has_many :lines, class_name: "Chouette::Line"
  has_many :companies, class_name: "Chouette::Company"
  has_many :networks, class_name: "Chouette::Network"
  has_many :group_of_lines, class_name: "Chouette::GroupOfLine"
  has_many :line_notices, class_name: "Chouette::LineNotice"

  validates :short_name, presence: true

  before_validation :define_line_referential, on: :create

  scope :by_text, ->(text) { text.blank? ? all : where('lower(line_providers.short_name) LIKE :t', t: "%#{text.downcase}%") }

  def workgroup
    workbench&.workgroup
  end

  private

  def define_line_referential
    self.line_referential ||= workgroup&.line_referential
  end
end
