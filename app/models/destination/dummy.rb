class Destination::Dummy < ::Destination
  option :result, enumerize: %w[successful unexpected_failure expected_failure]
  validates :result, presence: true

  def do_transmit(publication, report)
    raise "You asked me to fail" if result.to_s == "unexpected_failure"
    report.failed! message: "I failed, but it was expected" if result.to_s == "expected_failure"
  end
end
