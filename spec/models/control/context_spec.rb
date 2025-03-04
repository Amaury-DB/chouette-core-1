RSpec.describe Control::Context do
  let(:context) do
    Chouette.create do
      referential
    end
  end

  let(:control_list) do
    Control::List.create name: "Control List 1", workbench: context.workbench
  end
  let(:control_context) do
    Control::Context.create name: "Control Context 1", control_list: control_list
  end

  let(:control_list_run_referential) { context.referential }
  let(:control_list_run) do
    Control::List::Run.create(
      name: 'Control List Run 1',
      workbench: context.workbench,
      referential: control_list_run_referential,
      original_control_list: control_list
    )
  end
  let(:control_context_run) do
    Control::Context::Run.create name: "Control Context Run 1", control_list_run: control_list_run, options: {transport_mode: "bus"}, type: "Control::Context::Run"
  end
  let(:control_run) { Control::Base::Run.new control_list_run: control_list_run, control_context_run: control_context_run}

  describe '#validity_period' do
    subject { control_context_run.validity_period }

    context 'without referential' do
      let(:control_list_run_referential) { nil }

      it { is_expected.to be_nil }
    end

    context 'with referential' do
      let(:control_list_run) do
        Control::List::Run.create(
          name: 'Control List Run 1',
          referential: context.referential,
          workbench: context.workbench,
          original_control_list: control_list
        )
      end
      let(:referential_validity_period) { double(:referential_validity_period) }

      before { expect(context.referential).to receive(:validity_period).and_return(referential_validity_period) }

      it { is_expected.to eq(referential_validity_period) }
    end
  end

  describe ".context" do
    subject { model.pluck(:id) }

    before { control_list_run_referential&.switch }

    describe "#control_run is created with referential" do
      context "when model is stop_areas" do
        let(:model) { control_run.context.context.stop_areas }
        let(:referential_stop_area_ids) { context.referential.stop_areas.pluck(:id) }

        it {is_expected.to match_array(referential_stop_area_ids)}
      end

      context "when model is lines" do
        let(:model) { control_run.context.context.lines }
        let(:referential_line_ids) { context.referential.lines.pluck(:id) }

        it {is_expected.to match_array(referential_line_ids)}
      end

      context "when model is routes" do
        let(:model) { control_run.context.context.routes }
        let(:referential_route_ids) { context.referential.routes.pluck(:id) }

        it {is_expected.to match_array(referential_route_ids)}
      end

      context "when model is stop_points" do
        let(:model) { control_run.context.context.stop_points }
        let(:referential_stop_point_ids) { context.referential.stop_points.pluck(:id) }

        it {is_expected.to match_array(referential_stop_point_ids)}
      end

      context "when model is journey_patterns" do
        let(:model) { control_run.context.context.journey_patterns }
        let(:referential_journey_pattern_ids) { context.referential.journey_patterns.pluck(:id) }

        it {is_expected.to match_array(referential_journey_pattern_ids)}
      end

      context "when model is vehicle_journeys" do
        let(:model) { control_run.context.context.vehicle_journeys }
        let(:referential_vehicle_journey_ids) { context.referential.vehicle_journeys.pluck(:id) }

        it {is_expected.to match_array(referential_vehicle_journey_ids)}
      end

      context "when model is service_counts" do
        subject { control_run.context.context.respond_to?('service_counts') }

        it { is_expected.to be_truthy }
      end
    end

    describe "#control_run is created without referential" do
      let(:control_list_run_referential) { nil }

      context "when model is stop_areas" do
        let(:model) { control_run.context.context.stop_areas }
        let(:workbench_stop_area_ids) { context.workbench.stop_areas.pluck(:id) }

        it {is_expected.to match_array(workbench_stop_area_ids)}
      end

      context "when model is lines" do
        let(:model) { control_run.context.context.lines }
        let(:workbench_line_ids) { context.workbench.lines.pluck(:id) }

        it {is_expected.to match_array(workbench_line_ids)}
      end

      context "when model is routes" do
        let(:model) { control_run.context.context.routes }

        it {is_expected.to match_array([])}
      end

      context "when model is stop_points" do
        let(:model) { control_run.context.context.stop_points }

        it {is_expected.to match_array([])}
      end

      context "when model is journey_patterns" do
        let(:model) { control_run.context.context.journey_patterns }

        it {is_expected.to match_array([])}
      end

      context "when model is vehicle_journeys" do
        let(:model) { control_run.context.context.vehicle_journeys }

        it {is_expected.to match_array([])}
      end
    end
  end
end
