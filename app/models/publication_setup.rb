class PublicationSetup < ApplicationModel
  belongs_to :workgroup
  has_many :publications, dependent: :destroy
  has_many :destinations, dependent: :destroy

  validates :name, presence: true
  validates :workgroup, presence: true
  validates :export_type, presence: true

  accepts_nested_attributes_for :destinations, allow_destroy: true, reject_if: :all_blank

  scope :enabled, -> { where enabled: true }

  def export_class
    export_type.presence&.safe_constantize || Export::Base
  end

  def export_creator_name
    "#{self.class.ts} #{name}"
  end

  def new_export(extra_options={})
    options = (export_options || {}).dup.update(extra_options)
    export = export_class.new(options: options) do |export|
      export.creator = export_creator_name
    end
    if block_given?
      yield export
    end
    export
  end

  def new_exports(referential)
    if export_type == "Export::Netex" && export_options["export_type"] == "line"
      referential.metadatas_lines.map do |line|
        new_export(line_code: line.id) do |export|
         export.name = "#{self.class.ts} #{name} for line #{line.name}"
         export.referential = referential
       end
      end
    else
      export = new_export do |export|
        export.name = "#{self.class.ts} #{name}"
        export.referential = referential
        export.synchronous = true
      end
      [export]
    end
  end

  def publish(operation)
    publications.create!(parent: operation)
  end
end
