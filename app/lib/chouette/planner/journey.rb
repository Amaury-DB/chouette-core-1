# frozen_string_literal: true

module Chouette
  module Planner
    class Journey
      attr_accessor :cost, :extended, :origin_time_of_day

      def initialize(step: nil, reverse: false, origin_time_of_day: nil)
        steps << step if step
        @reverse = reverse
        @extended = false
        @cost = Float::INFINITY
        @origin_time_of_day = origin_time_of_day
      end

      def id
        @id ||= SecureRandom.uuid
      end
      attr_writer :id, :validity_period, :duration

      def reverse?
        @reverse
      end

      def extended?
        @extended
      end

      def extended!
        @extended = true
      end

      def each(&block)
        steps.each(&block)
      end

      delegate :last, to: :steps

      def extend(*steps, validity_period: nil)
        validity_period ||= ValidityPeriod.new
        dup._extend(*steps, validity_period: validity_period)
      end

      def validity_period
        @validity_period ||= ValidityPeriod.new
      end

      def merge(reverse_journey, merge_duration: 0)
        unless reverse_journey.reverse?
          raise ArgumentError, "Expected a reverse Journey, got #{reverse_journey.inspect}"
        end

        # Steps must be reverse
        merged_steps = reverse_journey.steps.reverse
        # Merge duration is used for first step and other durations are shift
        # The last duration is useless
        durations = [merge_duration, *merged_steps.map(&:duration)[0..-2]]

        merged_steps = [merged_steps, durations].transpose.map do |step, duration|
          step.with_duration(duration)
        end

        extend(*merged_steps, validity_period: reverse_journey.validity_period)
      end

      def duration
        @duration ||= steps.sum(&:duration)
      end

      def delta_time
        reverse? ? -duration : duration
      end

      def time_of_day
        return nil unless time_reference?

        origin_time_of_day + delta_time
      end

      def time_reference?
        origin_time_of_day.present?
      end

      def inspect
        "#<Chouette::Planner::Journey #{reverse? ? '◀️' : ''}#{extended? ? '✔️' : ''} ⚖️#{cost}/#{duration}s #{steps.inspect} 📅#{validity_period}>"
      end

      protected

      def _extend(*steps, validity_period: ValidityPeriod.new)
        self.steps.concat steps

        extended_validity_periods = steps.map(&:validity_period) + [validity_period]
        self.validity_period = self.validity_period.intersect(*extended_validity_periods)
        self.duration = nil
        self.extended = false
        self.id = nil

        self
      end

      def steps
        @steps ||= []
      end

      private

      def initialize_dup(source)
        @steps = source.steps.dup
      end
    end
  end
end
