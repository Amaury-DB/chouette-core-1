class Export::Resource < ActiveRecord::Base
  self.table_name = :export_resources

  include IevInterfaces::Resource

  belongs_to :export, class_name: Export::Base
  has_many :messages, class_name: "ExportMessage", foreign_key: :resource_id
end
