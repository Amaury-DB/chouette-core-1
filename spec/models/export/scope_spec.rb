RSpec.describe Export::Scope, use_chouette_factory: true do

  describe '#build' do
    context 'with lines' do
      xit 'should apply the Lines & Scheduled scopes' do
        scope = Export::Scope.build(referential, line_ids: [1])

        expect(scope).to be_a_kind_of(Export::Scope::Scheduled)
        expect(scope.current_scope).to be_a_kind_of(Export::Scope::Lines)
      end
    end

    context 'with date_range & lines' do
      xit 'should apply the Lines & DateRange scopes' do
        scope = Export::Scope.build(referential, date_range: Time.zone.today..1.month.from_now, line_ids: [1])

        expect(scope).to be_a_kind_of(Export::Scope::Scheduled)
        expect(scope.current_scope).to be_a_kind_of(Export::Scope::DateRange)
        expect(scope.current_scope.current_scope).to be_a_kind_of(Export::Scope::Lines)
      end
    end
  end

  let!(:context) do
    Chouette.create do
      line :first
      line :second
      line :third

      stop_area :specific_stop

      workbench do
        shape :shape_in_scope1
        shape :shape_in_scope2
        shape

        referential lines: [:first, :second, :third] do
          time_table :default
          time_table :orphan

          route :in_scope1, line: :first do
            journey_pattern :in_scope1, shape: :shape_in_scope1 do
              vehicle_journey :in_scope1, time_tables: [:default]
            end
            journey_pattern :in_scope2, shape: :shape_in_scope1 do
              vehicle_journey :in_scope2, time_tables: [:default]
            end
          end
          route :in_scope2, line: :second do
            journey_pattern :in_scope3, shape: :shape_in_scope2 do
              vehicle_journey :in_scope3, time_tables: [:default]
            end
            vehicle_journey :no_tt
          end
          route
        end
      end
    end
  end

  let(:referential) { context.referential }
  let(:all_scope) { Export::Scope::All.new(context.referential) }
  let(:default_scope) { Export::Scope::Base.new(all_scope) }
  let(:routes_in_scope) { [:in_scope1, :in_scope2].map { |n| context.route(n) } }

  before do
    referential.switch
  end

  describe Export::Scope::Lines do
    it_behaves_like 'Export::Scope::Base'

    let(:selected_line) { context.line(:first) }
    let(:scope) { Export::Scope::Scheduled.new(Export::Scope::Lines.new(default_scope, [selected_line.id])) }

    describe '#vehicle_journeys' do
      it 'should filter them by lines' do
        in_scope_vjs = selected_line.routes.flat_map(&:vehicle_journeys)
        out_scope_vj = context.vehicle_journey(:in_scope3)

        expect(scope.vehicle_journeys).to match_array in_scope_vjs
        expect(scope.vehicle_journeys).not_to include out_scope_vj
      end
    end

    describe '#metadatas' do
      subject { scope.metadatas }

      context 'no metadatas are related to lines' do
        before do
          allow(scope.current_scope).to receive(:selected_line_ids) { [] }
        end

        it { is_expected.to be_empty }
      end

      context 'some metadatas are related to to selected_lines' do
        before do
          allow(scope.current_scope).to receive(:selected_line_ids) { default_scope.metadatas.first.line_ids }
        end

        it { is_expected.not_to be_empty }
      end

    end

    describe '#organisations' do

      subject { scope.organisations }

      context 'no metadatas are related to organisations through referential_source' do
        it "returns the organisation which owns the Referential" do
          is_expected.to contain_exactly(referential.organisation)
        end
      end

      context 'some metadatas are related to organisations through referential_source' do
        before do
          # FIXME Use the referential .. as its own source for the test
          default_scope.metadatas.update_all referential_source_id: referential.id
        end

        it "returns related organisations" do
          is_expected.to contain_exactly(referential.organisation)
        end
      end
    end

    describe '#time_tables' do
      subject { scope.time_tables }

      let(:scope) { Export::Scope.build(referential, line_ids: selected_line_ids) }

      context 'when the lines associated to time tables are selected' do
        let(:selected_line_ids) { [ context.line(:first).id, context.line(:second).id] }

        it "the scope should contain the TimeTable 'default' and not contain the TimeTable 'orphan'" do
         is_expected.to match_array([context.time_table(:default)])
        end
      end

      context "when the line 'third' are selected" do
        let(:selected_line_ids) { [ context.line(:third).id] }

        it { is_expected.to be_empty }
      end

      context 'when no line is selected' do
        let(:selected_line_ids) { nil }

        it "the scope should contain the TimeTable 'default' and not contain the TimeTable 'orphan'" do
          is_expected.to match_array([context.time_table(:default), context.time_table(:orphan)])
        end
      end
    end
  end

  describe Export::Scope::Scheduled do
    it_behaves_like 'Export::Scope::Base'

    let(:scope) { Export::Scope::Scheduled.new(default_scope) }

    describe '#stop_areas' do
      subject { scope.stop_areas }

      let(:context) do
        Chouette.create do
          stop_area :stop_area1
          stop_area :stop_area2

          route :route, stop_areas: %i[stop_area1 stop_area2] do
            vehicle_journey :vehicle_journey
          end
        end
      end
      let(:stop_areas) { [context.stop_area(:stop_area1), context.stop_area(:stop_area2)] }
      let(:expected_routes) { [] }
      let(:expected_vehicle_journeys) { [] }

      before do
        expect(scope).to receive(:routes).and_return(expected_routes)
        expect(scope).to receive(:final_scope_vehicle_journeys).and_return(expected_vehicle_journeys)
      end

      context 'when no route nor vehicle journey is exported' do
        it { is_expected.to be_empty }
      end

      context 'when some routes are exported' do
        let(:expected_routes) { [context.route(:route)] }

        it { is_expected.to match_array(stop_areas) }
      end

      context 'when some vehicle journeys are exported' do
        let(:expected_routes) { [context.vehicle_journey(:vehicle_journey)] }

        it { is_expected.to match_array(stop_areas) }
      end
    end

    describe '#stop_area_groups' do
      subject { scope.stop_area_groups }

      let(:context) do
        Chouette.create do
          stop_area :stop_area1
          stop_area :stop_area2
          stop_area :other_stop_area

          stop_area_group :stop_area_group, stop_areas: %i[stop_area1]
          stop_area_group :other_stop_area_group, stop_areas: %i[other_stop_area]

          route :route, stop_areas: %i[stop_area1 stop_area2]
        end
      end
      let(:expected_routes) { [] }
      let(:stop_area_groups) { [context.stop_area_group(:stop_area_group)] }

      before { expect(scope).to receive(:routes).and_return(expected_routes) }

      context 'when no stop area are exported' do
        it { is_expected.to be_empty }
      end

      context 'when some routes are exported' do
        let(:expected_routes) { [context.route(:route)] }

        it { is_expected.to match_array(stop_area_groups) }
      end
    end

    describe '#lines' do
      subject { scope.lines }

      let(:context) do
        Chouette.create do
          line :line
          line :other_line

          referential lines: %i[line other_line] do
            route line: :line
          end
        end
      end
      let(:expected_routes) { Chouette::Route.none }
      let(:lines) { [context.line(:line)] }

      before { expect(scope).to receive(:routes).and_return(expected_routes) }

      context 'when no routes are exported' do
        it { is_expected.to be_empty }
      end

      context 'when some routes are exported' do
        let(:expected_routes) { Chouette::Route.all }

        it { is_expected.to match_array(lines) }
      end
    end

    describe '#line_groups' do
      subject { scope.line_groups }

      let(:context) do
        Chouette.create do
          line :line
          line :other_line

          line_group :line_group, lines: %i[line]
          line_group :other_line_group, lines: %i[other_line]

          referential lines: %i[line other_line]
        end
      end
      let(:expected_lines) { Chouette::Line.none }
      let(:line_groups) { [context.line_group(:line_group)] }

      before { expect(scope).to receive(:lines).and_return(expected_lines) }

      context 'when no lines are exported' do
        it { is_expected.to be_empty }
      end

      context 'when some lines are exported' do
        let(:expected_lines) { Chouette::Line.where(id: context.line(:line)) }

        it { is_expected.to match_array(line_groups) }
      end
    end

    describe '#vehicle_journeys' do
      it 'should filter in the ones with not empty timetables' do
        in_scope_vjs = %i[in_scope1 in_scope2 in_scope3].map { |n| context.vehicle_journey(n) }
        out_scope_vj = context.vehicle_journey(:no_tt)

        expect(scope.vehicle_journeys).to match_array(in_scope_vjs)
        expect(scope.vehicle_journeys).not_to include(out_scope_vj)
      end
    end

    describe '#fare_products' do
      subject { scope.fare_products }

      context 'when no Company is scoped' do
        let(:context) do
          Chouette.create do
            company :exported
            referential
            fare_product company: :exported
          end
        end

        before { allow(scope).to receive(:companies).and_return([]) }

        it { is_expected.to be_empty }
      end

      context 'when a Fare Product is associated to a scoped Company' do
        let(:context) do
          Chouette.create do
            company :exported
            referential
            fare_product company: :exported
          end
        end

        let(:fare_product) { context.fare_product }
        before { allow(scope).to receive(:companies).and_return([fare_product.company]) }

        it 'includes this Fare Product' do
          is_expected.to include(fare_product)
        end
      end

      context 'when a Fare Product is not associated to a scoped Company' do
        let(:context) do
          Chouette.create do
            referential

            company :exported

            company :not_exported
            fare_product company: :not_exported
          end
        end

        let(:fare_product) { context.fare_product }
        let(:exported_company) { context.company(:exported) }
        before { allow(scope).to receive(:companies).and_return([exported_company]) }

        it 'includes this Fare Product' do
          is_expected.to be_empty
        end
      end

      context 'when a Fare Product is not associated to a Company' do
        let(:context) do
          Chouette.create do
            referential
            company :exported
            fare_product company: :nil
          end
        end

        let(:fare_product) { context.fare_product }
        let(:exported_company) { context.company(:exported) }
        before { allow(scope).to receive(:companies).and_return([exported_company]) }

        it 'includes this Fare Product' do
          is_expected.to include(fare_product)
        end
      end
    end

    describe '#fare_validities' do
      subject { scope.fare_validities }

      context 'when no Fare Product is scoped' do
        let(:context) do
          Chouette.create do
            referential
            fare_validity
          end
        end

        before { allow(scope).to receive(:fare_products).and_return([]) }

        it { is_expected.to be_empty }
      end

      context 'when a Fare Validity is associated to a scoped Fare Product' do
        let(:context) do
          Chouette.create do
            referential
            fare_validity
          end
        end

        let(:fare_validity) { context.fare_validity }
        before { allow(scope).to receive(:companies).and_return(fare_validity.products) }

        it 'includes this Fare Validity' do
          is_expected.to include(fare_validity)
        end
      end

      context 'when a Fare Validity is not associated to a scoped Fare Product' do
        let(:context) do
          Chouette.create do
            referential
            fare_product :exported

            fare_product :not_exported
            fare_validity products: [:not_exported]
          end
        end

        let(:fare_validity) { context.fare_validity }
        let(:exported_fare_product) { context.fare_product :exported }
        before { allow(scope).to receive(:fare_products).and_return([exported_fare_product]) }

        it "doesn't include this Fare Validity" do
          is_expected.to_not include(fare_validity)
        end
      end
    end

    describe '#routing_constraint_zones' do
      subject { scope.routing_constraint_zones }

      context "when no Route is scoped" do
        let(:context) do
          Chouette.create { referential }
        end

        it { is_expected.to be_empty }
      end

      context "when a Route which a RoutingConstraintZone is scoped" do
        let(:context) do
          Chouette.create do
            route { routing_constraint_zone }
          end
        end
        before { allow(scope).to receive(:routes).and_return(referential.routes) }

        let(:routing_constraint_zone) { context.routing_constraint_zone }
        it "includes this RoutingConstraintZone" do
          is_expected.to include(routing_constraint_zone)
        end
      end

      context "when a Route which a RoutingConstraintZone is not scoped" do
        let(:context) do
          Chouette.create do
            route { routing_constraint_zone }
          end
        end
        before { allow(scope).to receive(:routes).and_return(Chouette::Route.none) }
        it { is_expected.to be_empty }
      end
    end

    describe '#companies' do
      subject { scope.companies }

      context 'when a Line with a Company is scoped' do
        let(:context) do
          Chouette.create do
            referential # useless .. but required by context ^ :(
            company :company
            line company: :company
          end
        end
        before { allow(scope).to receive(:lines).and_return(Chouette::Line.where(id: context.lines)) }

        let(:company) { context.company(:company) }

        it "includes this Company" do
          is_expected.to include(company)
        end
      end

      context 'when a Line with a secondary Company is scoped' do
        let(:context) do
          Chouette.create do
            referential # useless .. but required by context ^ :(
            company :secondary
            line secondary_companies: [ :secondary ]
          end
        end
        before { allow(scope).to receive(:lines).and_return(Chouette::Line.where(id: context.lines)) }

        let(:company) { context.company(:secondary) }

        it "includes this Company" do
          is_expected.to include(company)
        end
      end

      context "when a Line with a Company and a secondary Company isn't scoped" do
        let(:context) do
          Chouette.create do
            referential # useless .. but required by context ^ :(
            company :main
            company :secondary
            line company: :main, secondary_companies: [ :secondary ]
          end
        end
        before { allow(scope).to receive(:lines).and_return(Chouette::Line.none) }

        let(:main_company) { context.company(:main) }
        let(:secondary_company) { context.company(:secondary) }

        it { is_expected.to be_empty }
      end
    end
  end

  describe Export::Scope::DateRange do
    it_behaves_like 'Export::Scope::Base'

    let(:date_range) { Range.new(*context.time_table(:default).bounding_dates) }
    let(:period_before_daterange) { (date_range.begin - 100)..(date_range.begin - 10) }
    let(:scope) { Export::Scope::Scheduled.new(Export::Scope::DateRange.new(default_scope, date_range)) }

    describe '#vehicle_journeys' do
      it 'should filter in the ones with matching timetables' do
        in_scope_vjs = %i[in_scope1 in_scope2 in_scope3].map { |n| context.vehicle_journey(n) }
        out_scope_vj = context.vehicle_journey(:no_tt)
        expect(scope.vehicle_journeys).to match_array(in_scope_vjs)
        expect(scope.vehicle_journeys).not_to include(out_scope_vj)
      end

      it 'should filter in the ones with matching timetables (2)' do
        allow(scope.current_scope).to receive(:date_range) { period_before_daterange }

        expect(scope.vehicle_journeys).to be_empty
      end
    end

    describe '#time_tables' do
      it 'should filter in the ones overlap the daterange' do
        tt = context.time_table(:default)

        expect(scope.time_tables).to include(tt)
      end

      it 'should filter in the ones overlap the daterange (2)' do
        allow(scope.current_scope).to receive(:date_range) { period_before_daterange }

        expect(scope.time_tables).to be_empty
      end
    end

    describe '#metadatas' do
      it 'should filter in the ones overlap the daterange' do
        metadata = scope.metadatas.first

        expect(scope.metadatas).to include(metadata)

        allow(scope.current_scope).to receive(:date_range) { period_before_daterange }

        expect(scope.metadatas).to be_empty
      end
    end

    describe '#organisations' do
      before do
        # Use the referential .. as its own source for the test
        referential.metadatas.update_all referential_source_id: referential.id
      end

      it 'should filter in the ones related to metadatas overlapping the daterange' do
        organisation = scope.organisations.first

        expect(scope.organisations).to include(organisation)

        allow(scope.current_scope).to receive(:date_range) { period_before_daterange }

        expect(scope.metadatas).to be_empty
      end

    end

  end

  describe Export::Scope::Stateful do

    let(:scope) { Export::Scope::Stateful.new(default_scope) }
    let(:models) { referential.send(collection) }
    let(:model_from_exportables) { Exportable.all.map(&:model) }

    subject { scope.send collection }

    describe '#vehicle_journeys' do

      let(:collection) { 'vehicle_journeys' }

      it 'should create exportables' do
        expect { subject }.to change { Exportable.count }.from(0).to(models.count)
        expect(model_from_exportables).to match_array(models)
      end

      it 'should return vehicle_journeys from scope' do
        expect(subject).to match_array(models)
      end
    end

    describe '#time_tables' do
      let(:collection) { 'time_tables' }

      it 'should create exportables' do
        expect { subject }.to change { Exportable.count }.from(0).to(models.count)
        expect(model_from_exportables).to match_array(models)
      end

      it 'should return vehicle_journeys from scope' do
        expect(subject).to match_array(models)
      end
    end

    describe Export::Scope::Stateful::Loader do
      subject { described_class.new(scope, nil, Chouette::VehicleJourney).loaded_models }

      context 'when model scope is none' do
        before do
          allow(scope).to receive(:vehicle_journeys).and_return(Chouette::VehicleJourney.none)
        end

        it 'should return empty loaded models' do
          is_expected.to be_empty
        end
      end

      context 'when model scope contains vehicle journeys' do
        before do
          allow(scope).to receive(:vehicle_journeys).and_return(referential.vehicle_journeys)
        end

        it 'should contain loaded models' do
          is_expected.to match_array referential.vehicle_journeys
        end
      end
    end
  end
end
