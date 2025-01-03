# frozen_string_literal: true

RSpec.describe Workbench, type: :model do
  describe "validations" do
    it { is_expected.to validate_presence_of(:name) }
    it { is_expected.to validate_presence_of(:objectid_format) }

    it { is_expected.to belong_to(:organisation).optional }
    it { is_expected.to belong_to(:line_referential) }
    it { is_expected.to belong_to(:stop_area_referential) }
    it { is_expected.to belong_to(:workgroup) }
    it do
      allow_any_instance_of(described_class).to receive(:create_dependencies).and_return(nil)
      is_expected.to belong_to(:output).class_name('ReferentialSuite').required
    end

    it { is_expected.to have_many(:lines).through(:line_referential) }
    it { is_expected.to have_many(:networks).through(:line_referential) }
    it { is_expected.to have_many(:companies).through(:line_referential) }

    it { is_expected.to have_many(:stop_areas).through(:stop_area_referential) }
    it { is_expected.to have_many(:notification_rules).dependent(:destroy) }

    it { is_expected.to have_many(:calendars).dependent(:destroy) }

    context 'when the Workbench is waiting an associated Organisation' do
      before { allow(subject).to receive(:pending?) { true } }
      it { is_expected.to_not validate_presence_of(:organisation) }
      it { is_expected.to_not validate_presence_of(:prefix) }

      context 'when another Workbench has the invitation code "W-123-456-789"' do
        let!(:context) { Chouette.create { workbench invitation_code: 'W-123-456-789' } }
        it { is_expected.to_not allow_value('W-123-456-789').for(:invitation_code) }
      end
    end

    context 'when the Workbench is associated to an Organisation' do
      before { allow(subject).to receive(:pending?) { false } }
      it { is_expected.to validate_presence_of(:organisation) }
      it { is_expected.to validate_presence_of(:prefix) }
    end

    describe 'name uniqueness' do
      it 'can have a name already used in another workgroup' do
        context = Chouette.create do
          workgroup :workgroup1
          workgroup :workgroup2 do
            workbench name: 'Unique'
          end
        end
        subject.workgroup = context.workgroup(:workgroup1)
        is_expected.to allow_value('Unique').for(:name)
      end

      it 'cannot have a name already used in the same workgroup' do
        context = Chouette.create do
          workgroup :workgroup do
            workbench name: 'Unique'
          end
        end
        subject.workgroup = context.workgroup(:workgroup)
        is_expected.not_to allow_value('Unique').for(:name)
      end
    end
  end

  context 'aggregation setup' do
    context 'locked_referential_to_aggregate' do
      let(:workbench) { create(:workbench) }

      it 'should be nil by default' do
        expect(workbench.locked_referential_to_aggregate).to be_nil
      end

      it 'should only take values from the workbench output' do
        referential = create(:referential)
        workbench.locked_referential_to_aggregate = referential
        expect(workbench).to_not be_valid
        referential.referential_suite = workbench.output
        expect(workbench).to be_valid
      end

      it 'should not log a warning if the referential exists' do
        referential = create(:referential)
        referential.referential_suite = workbench.output
        workbench.update locked_referential_to_aggregate: referential
        expect(Rails.logger).to_not receive(:warn)
        expect(workbench.locked_referential_to_aggregate).to eq referential
      end

      it 'should log a warning if the referential does not exist anymore' do
        workbench.update_column :locked_referential_to_aggregate_id, Referential.last.id.next
        expect(Rails.logger).to receive(:warn)
        expect(workbench.locked_referential_to_aggregate).to be_nil
      end
    end

    context 'referential_to_aggregate' do
      let(:workbench) { create(:workbench) }
      let(:referential) { create(:referential) }
      let(:latest_referential) { create(:referential) }

      before(:each) do
        referential.update referential_suite: workbench.output
        latest_referential.update referential_suite: workbench.output
        workbench.output.update current: latest_referential
      end

      it 'should point to the current output' do
        expect(workbench.referential_to_aggregate).to eq latest_referential
      end

      context 'when designated a referential_to_aggregate' do
        before do
          workbench.update locked_referential_to_aggregate: referential
        end

        it 'should use this referential instead' do
          expect(workbench.referential_to_aggregate).to eq referential
        end
      end
    end
  end

  context '.lines' do
    let!(:ids) { ['STIF:CODIFLIGNE:Line:C00840', 'STIF:CODIFLIGNE:Line:C00086'] }
    let!(:organisation) { create :organisation, sso_attributes: { functional_scope: ids.to_json } }
    let(:workbench) { create :workbench, organisation: organisation }
    let(:lines){ workbench.lines }

    before do
      (ids + ['STIF:CODIFLIGNE:Line:0000']).each do |id|
        create :line, objectid: id, line_referential: workbench.line_referential
      end
    end

    context "with the default scope policy" do
      before do
        allow(Workgroup).to receive(:workbench_scopes_class).and_return(WorkbenchScopes::All)
      end

      it 'should retrieve all lines' do
        expect(lines.count).to eq 3
      end
    end
  end

  context '.stop_areas' do
    let(:sso_attributes){{stop_area_providers: %w(blublublu)}}
    let!(:organisation) { create :organisation, sso_attributes: sso_attributes }
    let(:workbench) { create :workbench, organisation: organisation, stop_area_referential: stop_area_referential }
    let(:stop_area_provider){ create :stop_area_provider, objectid: "FR1:OrganisationalUnit:blublublu:", stop_area_referential: stop_area_referential }
    let(:stop_area_referential){ create :stop_area_referential }
    let(:stop){ create :stop_area, stop_area_referential: stop_area_referential }
    let(:stop_2){ create :stop_area, stop_area_referential: stop_area_referential }

    before(:each) do
      stop
      stop_area_provider.stop_areas << stop_2
      stop_area_provider.save
    end

    context 'without a functional_scope' do
      before do
        allow(Workgroup).to receive(:workbench_scopes_class).and_return(WorkbenchScopes::All)
      end

      it 'should filter stops based on the stop_area_referential' do
        stops = workbench.stop_areas
        expect(stops.count).to eq 2
        expect(stops).to include stop_2
        expect(stops).to include stop
      end
    end
  end

  describe '#find_referential!' do
    let(:workbench) { context.workbench(:workbench) }
    let(:referential) { context.referential(:referential) }
    let(:referential_id) { referential.id }

    subject { workbench.find_referential!(referential_id) }

    context "when referential is workbench's referentials" do
      let(:context) do
        Chouette.create do
          workgroup do
            workbench :workbench do
              referential :referential
            end
          end
        end
      end

      it 'should return referential' do
        is_expected.to eq(referential)
      end
    end

    context "when referential is in workbench's output referentials" do
      let(:context) do
        Chouette.create do
          workgroup do
            workbench :workbench
            referential :referential
          end
        end.tap do |c|
          c.workbench(:workbench).output.referentials << c.referential(:referential)
        end
      end

      it 'should return referential' do
        is_expected.to eq(referential)
      end
    end

    context "when referential is in workgroup's output referentials" do
      let(:context) do
        Chouette.create do
          workgroup do
            workbench :workbench
            referential :referential
          end
        end.tap do |c|
          c.workgroup.output.referentials << c.referential(:referential)
        end
      end

      it 'should return referential' do
        is_expected.to eq(referential)
      end
    end

    context 'when none of the above' do
      let(:context) do
        Chouette.create do
          workbench :workbench
        end
      end
      let(:referential_id) { 0 }

      it 'should raise an error' do
        expect { subject }.to raise_error(ActiveRecord::RecordNotFound)
      end
    end
  end

  describe "#create_default_prefix" do
    subject { workbench.create_default_prefix }

    let(:organisation) { Organisation.new }
    let(:workbench) { Workbench.new organisation: organisation }

    context "when organisation code is 'test-abc'" do
      before { organisation.code = 'test-abc' }
      it { is_expected.to eq('test_abc') }
    end

    context "when organisation code is 'test+abc'" do
      before { organisation.code = 'test+abc' }
      it { is_expected.to eq('test_abc') }
    end
  end

  describe "#create_invitation_code" do
    let(:workbench) { Workbench.new }
    subject { workbench.create_invitation_code }

    it "defines Workbench invitation_code" do
      expect { subject }.to change(workbench, :invitation_code).from(nil).to(matching(/\AW-\d{3}-\d{3}-\d{3}\z/))
    end

    it { is_expected.to match(/\AW-\d{3}-\d{3}-\d{3}\z/) }
  end

  describe "on creation" do
    let(:context) { Chouette.create { workbench } }
    subject(:workbench) { context.workbench }

    it { is_expected.to have_same_attributes(:line_referential, than: workbench.workgroup) }
    it { is_expected.to have_same_attributes(:stop_area_referential, than: workbench.workgroup) }

    it { is_expected.to have_attributes(objectid_format: 'netex') }
    it { is_expected.to have_attributes(output: an_instance_of(ReferentialSuite)) }

    describe "prefix" do
      subject { workbench.prefix }

      it { is_expected.to match(%r{\A[0-9a-zA-Z_]+\Z}) }

      context "when Organisation code is 'Tôô Exotic'" do
        let(:context) do
          Chouette.create do
            organisation :first, code: 'Tôô Exotic'
            workbench organisation: :first
          end
        end

        it { is_expected.to eq("too_exotic") }
      end
    end

    describe "default Shape Provider" do
      subject { workbench.default_shape_provider }

      it "must be the first/single Shape Provider" do
        is_expected.to eq(workbench.shape_providers.first)
      end

      it { is_expected.to have_attributes(short_name: 'default') }
    end

    describe "default Line Provider" do
      subject { workbench.default_line_provider }

      context 'when disable_default_line_provider is false' do
        it "must be the first/single Line Provider" do
          is_expected.to eq(workbench.line_providers.first)
        end

        it { is_expected.to have_attributes(short_name: 'default', name: 'default') }

        context "when default line provider name is changed" do
          before { subject.update name: 'line_provider', short_name: 'line_provider' }

          it "must find the default line provider" do
            is_expected.to eq(workbench.line_providers.first)
          end
        end
      end

      context 'when disable_default_line_provider is true' do
        before { allow_any_instance_of(Workbench).to receive(:disable_default_line_provider).and_return(true) }

        it "is nil when no line providers exist" do
          is_expected.to eq(nil)
        end

      end
    end

    describe "default Stop Area Provider" do
      subject { workbench.default_stop_area_provider }

      it "must be the first/single Stop Area Provider" do
        is_expected.to eq(workbench.stop_area_providers.first)
      end

      it { is_expected.to have_attributes(name: 'Default') }
    end

    context "without an Organisation" do
      let(:context) { Chouette.create { workbench organisation: nil } }

      it { is_expected.to have_attributes(organisation: a_nil_value, prefix: a_nil_value) }
      it { is_expected.to have_attributes(invitation_code: match(/\AW-\d{3}-\d{3}-\d{3}\z/)) }
    end
  end

  describe '#calendars_with_shared' do
    subject { workbench.calendars_with_shared }

    let(:workbench) { create(:workbench) }
    let(:other_organisation_workbench) { create(:workbench, workgroup: workbench.workgroup) }
    let(:other_workgroup_workbench) { create(:workbench, organisation: workbench.organisation) }
    let!(:non_shared_workbench_calendar) do
      create(:calendar, workbench: workbench)
    end
    let!(:shared_workbench_calendar) do
      create(:calendar, workbench: workbench, shared: true)
    end
    let!(:non_shared_other_organisation_calendar) do
      create(:calendar, workbench: other_organisation_workbench)
    end
    let!(:shared_other_organisation_calendar) do
      create(:calendar, workbench: other_organisation_workbench, shared: true)
    end
    let!(:non_shared_other_workgroup_calendar) do
      create(:calendar, workbench: other_workgroup_workbench)
    end
    let!(:shared_other_workgroup_calendar) do
      create(:calendar, workbench: other_workgroup_workbench, shared: true)
    end

    it 'returns only its calendars + shared calendars' do
      is_expected.to match_array(
        [
          non_shared_workbench_calendar,
          shared_workbench_calendar,
          shared_other_organisation_calendar
        ]
      )
    end
  end

  describe "#control_lists_shared_with_workgroup" do
    let(:context) do
      Chouette.create do
        workbench :first
        workbench :second
        workbench :third
      end
    end

    let(:first_workbench) { context.workbench(:first) }
    let(:second_workbench) { context.workbench(:second) }

    let!(:first_control_list) { first_workbench.control_lists.create! name: "first control list" }
    let!(:second_control_list) { second_workbench.control_lists.create! name: "second control list", shared: true }
    let!(:third_control_list) { second_workbench.control_lists.create! name: "third control list" }

    subject { first_workbench.control_lists_shared_with_workgroup.all }

    it { is_expected.to match_array([first_control_list, second_control_list]) }
    it { is_expected.not_to include(third_control_list)}
  end
end

RSpec.describe Workbench::Confirmation do
  describe 'validation' do
    describe 'of invitation_code' do
      it { is_expected.to_not allow_value('dummy', '123-456-789').for(:invitation_code) }

      context 'when a Workbench exists with invitation code "W-123-456-789"' do
        before { Chouette.create { workbench invitation_code: 'W-123-456-789', organisation: nil } }
        it { is_expected.to allow_value('W-123-456-789').for(:invitation_code) }
      end

      context 'when a Workbench exists with invitation code "123-456-789"' do
        before { Chouette.create { workbench invitation_code: '123-456-789', organisation: nil } }
        it { is_expected.to allow_value('123-456-789').for(:invitation_code) }
      end

      context 'when a Workbench with an organisation exists with invitation code "W-123-456-789"' do
        before { Chouette.create { workbench invitation_code: 'W-123-456-789' } }
        it { is_expected.not_to allow_value('W-123-456-789').for(:invitation_code) }
      end

      context 'when a Workbench::Sharing exists with invitation code "S-123-456-789"' do
        before do
          Chouette.create do
            workbench_sharing invitation_code: 'S-123-456-789', recipient_type: 'Organisation', recipient_id: nil
          end
        end
        it { is_expected.to allow_value('S-123-456-789').for(:invitation_code) }
      end

      context 'when a Workbench::Sharing with a recipient exists with invitation code "S-123-456-789"' do
        before { Chouette.create { workbench_sharing invitation_code: 'S-123-456-789' } }
        it { is_expected.not_to allow_value('S-123-456-789').for(:invitation_code) }
      end

      context 'when a Workbench exists with invitation code "Z-123-456-789"' do
        before { Chouette.create { workbench invitation_code: 'Z-123-456-789' } }
        it { is_expected.not_to allow_value('123-456-789').for(:invitation_code) }
      end
    end
  end

  let(:context) do
    Chouette.create do
      workbench invitation_code: 'W-123-456-789', organisation: nil
    end
  end
  let(:organisation) { Chouette.create { organisation }.organisation }
  let(:workbench) { context.workbench }
  let(:user) { nil }
  let(:invitation_code) { 'W-123-456-789' }

  subject(:workbench_confirmation) do
    Workbench::Confirmation.new(invitation_code: invitation_code, organisation: organisation, user: user)
  end

  context '#save' do
    subject { workbench_confirmation.save }

    it 'workbench is associated to the new Organisation' do
      expect { subject }.to change { workbench.reload.organisation }.from(nil).to(organisation)
    end

    it 'workbench loses its invitation code' do
      expect { subject }.to change { workbench.reload.invitation_code }.from(invitation_code).to(nil)
    end

    context 'when a workbench sharing invitation code is provided' do
      let(:invitation_code) { 'S-123-456-789' }
      let(:workbench_sharing) { context.workbench_sharing }

      context 'with a user recipient' do
        let(:context) do
          Chouette.create do
            workbench do
              workbench_sharing recipient_type: 'User', invitation_code: 'S-123-456-789'
            end
          end
        end
        let(:user) { Chouette.create { user }.user }

        it 'workbench does not change its Organisation' do
          expect { subject }.not_to change { workbench.reload.organisation }.from(be_present)
        end

        it 'assigns user to workbench sharing' do
          expect { subject }.to change { workbench_sharing.reload.recipient }.from(nil).to(user)
        end
      end

      context 'with a organisation recipient' do
        let(:context) do
          Chouette.create do
            workbench do
              workbench_sharing recipient_type: 'Organisation', invitation_code: 'S-123-456-789'
            end
          end
        end

        it 'workbench does not change its Organisation' do
          expect { subject }.not_to change { workbench.reload.organisation }.from(be_present)
        end

        it 'assigns organisation to workbench sharing' do
          expect { subject }.to change { workbench_sharing.reload.recipient }.from(nil).to(organisation)
        end
      end
    end
  end
end
