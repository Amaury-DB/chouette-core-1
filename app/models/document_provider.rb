class DocumentProvider < ActiveRecord::Base
  belongs_to :workbench # CHOUETTE-3247 required: true

  has_many :documents

  before_destroy :can_destroy?, prepend: true

  validates :name, presence: true
  validates :short_name, presence: true, uniqueness: { scope: :workbench }, format: { with: /\A[0-9a-zA-Z_]+\Z/ }

  def used?
    documents.exists?
  end

  private

  def can_destroy?
    if used?
      errors.add(:base, "Can't be destroy because it has at least one document provider")
      throw :abort
    end
  end
end
