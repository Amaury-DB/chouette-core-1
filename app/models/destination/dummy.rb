if ::Destination.enabled?("dummy")
  class Destination::Dummy < ::Destination
    option :result, collection: %w(successful unexpected_failure expected_failure), required: true

    def do_transmit(publication, report)
      raise "You asked me to fail" if result.to_s == "unexpected_failure"
      report.failed! "I failed, but it was expected"  if result.to_s == "expected_failure"
    end
  end
end
