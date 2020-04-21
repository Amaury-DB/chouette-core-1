module Chouette
  module Sync
    class Counters

      def initialize(initial_counts = {})
        @counts = Hash.new { |h,k| h[k] = 0 }
        @counts.merge! initial_counts.slice(*TYPES)
      end

      TYPES = %i{create update delete errors}
      def self.types
        TYPES
      end

      def check_type!(type)
        unless TYPES.include?(type)
          raise "Unsupported type: #{type}"
        end
      end

      def count(type)
        check_type! type
        counts[type]
      end

      types.each do |type|
        define_method type do
          count type
        end
      end

      def increment_count(type, count: 1)
        check_type! type
        counts[type] += count
      end

      def sum(other)
        added_counts = counts.merge(other.counts) { |_, a, b| a + b }
        self.class.new added_counts
      end

      def sum!(other)
        @counts = counts.merge(other.counts) { |_, a, b| a + b }
      end

      def to_hash
        counts.dup
      end

      def self.sum(*counters)
        counters.flatten!

        counters.each_with_object(counters.shift.dup) do |counter, sum|
          sum.sum! counter
        end
      end

      protected

      attr_reader :counts

    end
  end
end
