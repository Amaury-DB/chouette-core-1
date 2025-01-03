# frozen_string_literal: true

module Chouette
  class TimeTableDate < Referential::ActiveRecord
    include ChecksumSupport

    belongs_to :time_table, inverse_of: :dates # CHOUETTE-3247 null: false

    validates :date, presence: true

    with_options(if: -> { validation_context != :inserter }) do |except_in_inserter_context|
      except_in_inserter_context.validates :date, uniqueness: { scope: :time_table_id }
    end

    scope :in_dates, -> { where(in_out: true) }
    scope :in_date_range, -> (date_range) { where("date between ? and ?", date_range.min, date_range.max) }

    scope :included, -> { where in_out: true }
    scope :excluded, -> { where in_out: false }

    def self.model_name
      ActiveModel::Name.new Chouette::TimeTableDate, Chouette, "TimeTableDate"
    end

    def in?
      in_out == true
    end

    def out?
      in_out == false || in_out.nil?
    end

    alias included? in?
    alias excluded? out?

    def checksum_attributes(db_lookup = true)
      attrs = ['date', 'in_out']
      self.slice(*attrs).values
    end
  end
end
