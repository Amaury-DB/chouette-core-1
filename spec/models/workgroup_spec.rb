RSpec.describe Workgroup, type: :model do

  let(:context) { Chouette.create { workgroup } }
  let(:workgroup) { context.workgroup }

  context "associations" do
    it{ should have_many(:workbenches) }

    it { is_expected.to belong_to(:owner).required }
    it { is_expected.to belong_to(:stop_area_referential).required }
    it { is_expected.to belong_to(:line_referential).required }

    it{ should validate_uniqueness_of(:name) }
    it{ should validate_uniqueness_of(:stop_area_referential_id) }
    it{ should validate_uniqueness_of(:line_referential_id) }
    it{ should validate_uniqueness_of(:shape_referential_id) }

    it 'is valid with both associations' do
      expect(workgroup).to be_valid
    end
  end

  describe "#organisations" do
    let(:context) do
      Chouette.create do
        workgroup do
          workbench :first
          workbench :second
        end
      end
    end

    let(:workbench1) { context.workbench(:first) }
    let(:workbench2) { context.workbench(:second) }

    subject { workgroup.organisations }

    it "includes organisations of all workbenches in the workgroup" do
      is_expected.to match_array([workbench1.organisation, workbench2.organisation])
    end
  end

  describe "#nightly_aggregate_timeframe?" do
    let(:nightly_aggregation_time) { "15:15:00" }
    let(:nightly_aggregate_enabled) { false }

    before do
      workgroup.update nightly_aggregate_time: nightly_aggregation_time,
                       nightly_aggregate_enabled: nightly_aggregate_enabled
    end

    let(:time_at_1515) { Time.now.beginning_of_day + 15.hours + 15.minutes }

    context "when nightly_aggregate_enabled is true" do
      let(:nightly_aggregate_enabled) { true }

      it "returns true when inside timeframe" do
        Timecop.freeze(time_at_1515) do
          expect(workgroup.nightly_aggregate_timeframe?).to be_truthy
        end
      end

      it "returns false when outside timeframe" do
        Timecop.freeze(time_at_1515 - 20.minutes) do
          expect(workgroup.nightly_aggregate_timeframe?).to be_falsy
        end
      end

      it "returns false when inside timeframe but already done" do
        workgroup.nightly_aggregated_at = time_at_1515
        Timecop.freeze(time_at_1515) do
          expect(workgroup.nightly_aggregate_timeframe?).to be_falsy
        end
      end
    end

    context "when nightly_aggregate_enabled is false" do
      it "is false even within timeframe" do
        Timecop.freeze(time_at_1515) do
          expect(workgroup.nightly_aggregate_timeframe?).to be_falsy
        end
      end
    end
  end

  describe "#nightly_aggregate!" do
    before do
      workgroup.update nightly_aggregate_enabled: true,
                       nightly_aggregate_time: '15:15:00'
    end

    let(:time_at_1515) { Time.now.beginning_of_day + 15.hours + 15.minutes }

    context "when no aggregatable referential is found" do
      it "returns with a log message" do
        Timecop.freeze(time_at_1515) do
          expect { workgroup.nightly_aggregate! }.not_to change {
            workgroup.aggregates.count
          }
        end
      end
    end

    context "when we have rollbacked to a previous aggregate" do
      let(:workbench) { create(:workbench, workgroup: workgroup) }
      let(:referential) { create(:referential, organisation: workbench.organisation) }
      let(:aggregatable) { create(:workbench_referential, workbench: workbench) }
      let(:referential_2) { create(:referential, organisation: workbench.organisation) }
      let(:aggregate) { create(:aggregate, workgroup: workgroup)}
      let(:aggregate_2) { create(:aggregate, workgroup: workgroup)}
      let(:referential_suite) { create(:referential_suite, current: aggregatable) }
      let(:workgroup_referential_suite) { create(:referential_suite, current: referential_2, referentials: [referential, referential_2]) }

      before do
        aggregate.update new: referential, status: :successful
        aggregatable
        aggregate_2.update new: referential_2

        workbench.update(output: referential_suite)
        workgroup.update(output: workgroup_referential_suite)
        aggregate.rollback!
        expect(workgroup.output.current).to eq referential
      end

      it "returns with a log message" do
        Timecop.freeze(Time.now.beginning_of_day + 6.months + 15.hours + 15.minutes) do
          # expect(Rails.logger).to receive(:info).with(/\ANo aggregatable referential found/)

          expect { workgroup.nightly_aggregate! }.not_to change {
            workgroup.aggregates.count
          }
        end
      end
    end

    context "when aggregatable referentials are found" do
      let(:workbench) { create(:workbench, workgroup: workgroup) }
      let(:referential) { create(:referential, organisation: workbench.organisation, workbench: workbench) }
      let(:referential_suite) { create(:referential_suite, current: referential) }

      before do
        workbench.update(output: referential_suite)
      end

      it "creates a new aggregate" do
        Timecop.freeze(Time.now.beginning_of_day + 6.months + 15.hours + 15.minutes) do
          expect { referential.workgroup.nightly_aggregate! }.to change {
            referential.workgroup.aggregates.count
          }.by(1)
          expect(referential.workgroup.aggregates.where(creator: 'CRON')).to exist
        end
      end
    end
  end

  describe "when a workgroup is purged" do
    let!(:workgroup) { create(:workgroup, deleted_at: Time.now) }
    let!(:workbench) { create(:workbench, workgroup: workgroup) }
    let!(:new_referential) { create(:referential, organisation: workbench.organisation, workbench: workbench) }
    let!(:field){ create(:custom_field, workgroup: workgroup) }
    let!(:publication_api) { create(:publication_api, workgroup: workgroup) }
    let!(:publication_setup) { create(:publication_setup, workgroup: workgroup)}
    let!(:calendar) { create(:calendar, workgroup: workgroup)}


    let!(:line) { create(:line, line_referential: referential.line_referential) }
    let!(:route) { create(:route, line: line)}
    let!(:journey_pattern) { create(:journey_pattern, route: route) }


    it "should cascade destroy every related object" do
      Workgroup.purge_all

      # The schema that contains our deleted referential data should be destroyed (route, jp, timetables, etc)
      expect(ActiveRecord::Base.connection.schema_names).not_to include(new_referential.slug)

      expect(Chouette::Line.where(id: line.id).exists?).to be_truthy

      [workgroup, workbench, new_referential, field, calendar, new_referential, publication_api, publication_setup].each do |record|
        expect{record.reload}.to raise_error ActiveRecord::RecordNotFound
      end
    end

  end
end
