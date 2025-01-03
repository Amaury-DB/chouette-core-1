class Export::Message < ApplicationModel
  self.table_name = :export_messages

  include IevInterfaces::Message

  belongs_to :export, class_name: 'Export::Base' # TODO: CHOUETTE-3247 optional: true?
end
