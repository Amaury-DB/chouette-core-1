module Chouette
  class TimeTableDate < Chouette::ActiveRecord
    include ChecksumSupport
    acts_as_copy_target

    belongs_to :time_table, inverse_of: :dates

    validates_presence_of :date
    validates_uniqueness_of :date, :scope => :time_table_id

    scope :in_dates, -> { where(in_out: true) }
    scope :in_date_range, -> (date_range) { where("date between ? and ?", date_range.min, date_range.max) }

    def self.model_name
      ActiveModel::Name.new Chouette::TimeTableDate, Chouette, "TimeTableDate"
    end

    def in?
      in_out == true
    end

    def out?
      in_out == false || in_out.nil?
    end

    def checksum_attributes(db_lookup = true)
      attrs = ['date', 'in_out']
      self.slice(*attrs).values
    end
  end
end
