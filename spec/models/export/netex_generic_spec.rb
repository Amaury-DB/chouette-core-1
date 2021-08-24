RSpec.describe Export::NetexGeneric do

  describe "#content_type" do

    subject { export.content_type }

    context "when a profile is selected" do
      let(:export) { Export::NetexGeneric.new profile: 'european' }
      it { is_expected.to eq('application/zip') }
    end

    context "when no profile is selected" do
      let(:export) { Export::NetexGeneric.new profile: 'none' }
      it { is_expected.to eq('text/xml') }
    end

  end

  describe "#file_extension" do

    subject { export.file_extension }

    context "when a profile is selected" do
      let(:export) { Export::NetexGeneric.new profile: 'european' }
      it { is_expected.to eq('zip') }
    end

    context "when no profile is selected" do
      let(:export) { Export::NetexGeneric.new profile: 'none' }
      it { is_expected.to eq('xml') }
    end

  end

  describe "#netex_profile" do

    subject { export.netex_profile }

    context "when a profile is selected" do
      let(:export) { Export::NetexGeneric.new profile: 'european' }
      it { is_expected.to be_instance_of(Netex::Profile::European) }
    end

    context "when no profile is selected" do
      let(:export) { Export::NetexGeneric.new profile: 'none' }
      it { is_expected.to be_nil }
    end

  end

  describe "Lines export" do

    describe Export::NetexGeneric::Lines::Decorator do

      let(:line) { Chouette::Line.new }
      let(:decorator) { Export::NetexGeneric::Lines::Decorator.new line }

      describe "#netex_transport_submode" do
        subject { decorator.netex_transport_submode }

        context "when transport submode is 'undefined'" do
          before { line.transport_submode = :undefined }

          it { is_expected.to be_nil }
        end

        context "when transport submode is a standard value" do
          before { line.transport_submode = :schoolBus }

          it "is the same value than the line submode" do
            is_expected.to eq(line.transport_submode)
          end

        end

      end

    end

  end

  describe "Routes export" do

    let(:target) { MockNetexTarget.new }
    let(:export_scope) { Export::Scope::All.new context.referential }
    let(:export) { Export::NetexGeneric.new export_scope: export_scope, target: target }

    let(:part) do
      Export::NetexGeneric::Routes.new export
    end

    let(:context) do
      Chouette.create do
        3.times { route }
      end
    end

    let(:routes) { context.routes }
    before { context.referential.switch }

    it "create a Netex::Route for each Chouette Route and a Netex::Direction for routes having a published_name" do
      part.export!
      count = routes.count + routes.count { |route| route.published_name.present? }
      expect(target.resources).to have_attributes(count: count)

      routes_resources = target.resources.select { |r| r.is_a? Netex::Route }

      routes_resources.each do |resource|
        route = Chouette::Route.find_by_objectid! resource.id

        expect(route).to be

        expect(resource.line_ref).to be
        expect(resource.line_ref.ref).to eq(route.line.objectid)
        expect(resource.line_ref.type).to eq('LineRef')

        if route.published_name
          expect(resource.direction_ref).to be
          expect(resource.direction_ref.ref).to eq(route.objectid.gsub(/r|Route/, 'Direction'))
          expect(resource.direction_ref.type).to eq('DirectionRef')
        end
      end
    end

    it 'create a Netex::Direction for each Chouette Route that have a published_name' do
      part.export!

      directions = target.resources.select { |r| r.is_a? Netex::Direction }

      routes_with_published_name_count = routes.count { |r| r.published_name.present? }

      expect(directions.count).to eq(routes_with_published_name_count)
    end

    it "create Netex::Routes with line_id tag" do
      routes.each { |route| export.resource_tagger.register_tag_for(route.line) }
      part.export!
      expect(target.resources).to all(have_tag(:line_id))
    end

    describe Export::NetexGeneric::Routes::Decorator do

      let(:route) { Chouette::Route.new }
      let(:decorator) { Export::NetexGeneric::Routes::Decorator.new route }

      describe "#netex_attributes" do

        subject { decorator.netex_attributes }

        it "includes the same data_source_ref than the Route" do
          route.data_source_ref = "dummy"
          is_expected.to include(data_source_ref: route.data_source_ref)
        end

        it "includes a direction_ref if a published_name is defined" do
          route.objectid = "chouette:Route:1:"
          route.published_name = "dummy"
          is_expected.to have_key(:direction_ref)
        end

        it "doesn't include a direction_ref if a published_name isn't defined" do
          route.published_name = nil
          is_expected.to include(direction_ref: nil)
        end

      end

    end

    describe Export::NetexGeneric::StopPointDecorator do

      let(:stop_point) { Chouette::StopPoint.new position: 0 }
      let(:decorator) { Export::NetexGeneric::StopPointDecorator.new stop_point }

      describe "#netex_order" do

        subject { decorator.netex_order }

        it "returns the StopPoint position plus one (to avoid zero value)" do
          is_expected.to be(stop_point.position+1)
        end

      end

      describe "#stop_point_in_journey_pattern_id" do

        subject { decorator.stop_point_in_journey_pattern_id }

        context "when journey_pattern_id is 'chouette:JourneyPattern:1:LOC' and object_id is 'chouette:StopPointInJourneyPattern:2:LOC' and " do
          before do
            decorator.journey_pattern_id = 'chouette:JourneyPattern:1:LOC'
            stop_point.objectid = 'chouette:StopPointInJourneyPattern:2:LOC'
          end

          it { is_expected.to eq('chouette:StopPointInJourneyPattern:1-2:LOC') }
        end
      end

    end

  end

  describe "Stops export" do
    let(:target) { MockNetexTarget.new }
    let(:export_scope) { Export::Scope::All.new context.referential }
    let(:export) { Export::NetexGeneric.new export_scope: export_scope, target: target }

    let(:part) do
      Export::NetexGeneric::Stops.new export
    end

    let(:context) do
      Chouette.create do
        3.times { stop_point }
      end
    end

    before { context.referential.switch }

    it "create Netex resources with correct coordinates" do
      part.export!
      context.stop_points.each do |sp|
        expect(target.resources.find { |e| e.longitude == sp.stop_area.longitude && e.latitude == sp.stop_area.latitude }).to be_truthy
      end
    end

    describe Export::NetexGeneric::StopDecorator do
      let(:stop_area) { Chouette::StopArea.new }
      let(:decorator) { Export::NetexGeneric::StopDecorator.new stop_area }

      describe "#netex_alternate_identifiers" do
        subject { decorator.netex_alternate_identifiers }

        context "when StopArea registration number is 'dummy'" do
          before { stop_area.registration_number = 'dummy' }
          it { is_expected.to include(an_object_having_attributes(key: "external", value: "dummy", type_of_key: "ALTERNATE_IDENTIFIER")) }
        end

        context "when StopArea registration number is nil" do
          before { stop_area.registration_number = nil }
          it { is_expected.to_not include(an_object_having_attributes(key: "external")) }
        end

        context "when StopArea code 'public' exists with value 'dummy'" do
          before { stop_area.codes << Code.new(code_space: CodeSpace.new(short_name: 'public'), value: 'dummy') }
          it { is_expected.to include(an_object_having_attributes(key: "public", value: "dummy", type_of_key: "ALTERNATE_IDENTIFIER")) }
        end
      end
    end
  end

  describe "StopPoints export" do

    let(:target) { MockNetexTarget.new }
    let(:export_scope) { Export::Scope::All.new context.referential }
    let(:export) { Export::NetexGeneric.new export_scope: export_scope, target: target }

    let(:part) do
      Export::NetexGeneric::StopPoints.new export
    end

    let(:context) do
      Chouette.create do
        3.times { stop_point }
      end
    end

    before { context.referential.switch }

    it "create Netex resources with line_id tag" do
      context.routes.each { |route| export.resource_tagger.register_tag_for(route.line) }
      part.export!
      expect(target.resources).to all(have_tag(:line_id))
    end

  end

  describe "JourneyPatterns export" do

    let(:target) { MockNetexTarget.new }
    let(:export_scope) { Export::Scope::All.new context.referential }
    let(:export) { Export::NetexGeneric.new export_scope: export_scope, target: target }

    let(:part) do
      Export::NetexGeneric::JourneyPatterns.new export
    end

    let(:context) do
      Chouette.create do
        3.times { journey_pattern }
      end
    end

    let(:journey_patterns) { context.journey_patterns }

    before { context.referential.switch }

    it "create a Netex::JourneyPattern for each Chouette JourneyPattern" do
      part.export!
      count = journey_patterns.count + journey_patterns.count { |j| j.published_name.present? }
      expect(target.resources).to have_attributes(count: count)

      jp_resources = target.resources.select { |r| r.is_a? Netex::ServiceJourneyPattern }

      jp_resources.each do |resource|
        jp = Chouette::JourneyPattern.find_by_objectid! resource.id

        expect(jp).to be

        if jp.published_name
          expect(resource.destination_display_ref).to be
          expect(resource.destination_display_ref.ref).to eq(jp.objectid.gsub(/j|JourneyPattern/) { 'DestinationDisplay' })
          expect(resource.destination_display_ref.type).to eq('DestinationDisplayRef')
        end
      end
    end

    it 'creates a Netex::DestinationDisplay for each Chouette Route having a published_name' do
      part.export!

      destination_displays = target.resources.select { |r| r.is_a? Netex::DestinationDisplay }

      jp_with_published_name_count = journey_patterns.count { |jp| jp.published_name.present? }

      expect(destination_displays.count).to eq(jp_with_published_name_count)
    end

    it "create Netex resources with line_id tag" do
      context.routes.each { |route| export.resource_tagger.register_tag_for(route.line) }
      part.export!
      expect(target.resources).to all(have_tag(:line_id))
    end

  end

  describe "VehicleJourneys export" do

    let(:target) { MockNetexTarget.new }
    let(:export_scope) { Export::Scope::All.new context.referential }
    let(:export) { Export::NetexGeneric.new export_scope: export_scope, target: target }

    let(:part) do
      Export::NetexGeneric::VehicleJourneys.new export
    end

    let(:context) do
      Chouette.create do
        3.times { vehicle_journey }
      end
    end

    let(:vehicle_journeys) { context.vehicle_journeys }
    let(:vehicle_journey_at_stops) { vehicle_journeys.flat_map { |vj| vj.vehicle_journey_at_stops } }

    before { context.referential.switch }

    it "create Netex resources with line_id tag" do
      context.routes.each { |route| export.resource_tagger.register_tag_for(route.line) }
      part.export!
      expect(target.resources).to all(have_tag(:line_id))
    end

    describe Export::NetexGeneric::VehicleJourneys::Decorator do
      let(:vehicle_journey) { vehicle_journeys.first }
      let(:decorator) { Export::NetexGeneric::VehicleJourneys::Decorator.new vehicle_journey }

      describe "#vehicle_journey_at_stops" do
        subject { decorator.vehicle_journey_at_stops }

        it "is ordered by stop point position" do
          expect(subject.map { |s| s.stop_point.position }).to eq([0, 1, 2])
        end
      end
    end

    describe 'VehicleJourneyAtStop export' do
      context 'when stop_area is present' do
        before do
          vehicle_journey_at_stops.each do |vjas|
            vjas.update(stop_area: vjas.stop_point.stop_area)
          end
        end

        it 'should create a Netex::VehicleJourneyStopAssignment' do
          context.routes.each { |route| export.resource_tagger.register_tag_for(route.line) }
          part.export!

          vjas_assignments = target.resources.select { |r| r.is_a? Netex::VehicleJourneyStopAssignment }

          expect(vjas_assignments.count).to eq(vehicle_journey_at_stops.count)

          vjas_assignments.each do |vjas_assignment|
            expect(vjas_assignment.id).to include('VehicleJourneyStopAssignment')
            expect(vjas_assignment.scheduled_stop_point_ref).to be_kind_of(Netex::Reference)
            expect(vjas_assignment.quay_ref).to be_kind_of(Netex::Reference)
            expect(vjas_assignment.vehicle_journey_refs).to be_kind_of(Array)
            expect(vjas_assignment.vehicle_journey_refs.size).to eq(1)
          end
        end
      end

      context 'when stop_area is absent' do
        it 'should not create a Netex::VehicleJourneyStopAssignment' do
          context.routes.each { |route| export.resource_tagger.register_tag_for(route.line) }
          part.export!

          vjas_assignments_count = target.resources.count { |r| r.is_a? Netex::VehicleJourneyStopAssignment }

          expect(vjas_assignments_count).to eq(0)
        end
      end
    end
  end

  describe 'TimeTables export' do

    describe Export::NetexGeneric::TimeTableDecorator do
      let(:time_table) { Chouette::TimeTable.new }
      let(:decorated_tt) { Export::NetexGeneric::TimeTableDecorator.new time_table }
      let(:netex_resources) { decorated_tt.netex_resources }
      let(:operating_periods) { netex_resources.select { |r| r.is_a? Netex::OperatingPeriod }}
      let(:day_type_assignments) { netex_resources.select { |r| r.is_a? Netex::DayTypeAssignment }}

      describe '#day_type_attributes' do
        let(:day_type_attributes) { decorated_tt.day_type_attributes }

        it 'uses TimeTable objectid as Netex id' do
          expect(day_type_attributes[:id]).to eq(time_table.objectid)
        end

        it 'uses TimeTable data_source_ref as Netex data_source_ref' do
          expect(day_type_attributes[:data_source_ref]).to eq(time_table.data_source_ref)
        end

        it 'uses TimeTable comment as Netex name' do
          expect(day_type_attributes[:name]).to eq(time_table.comment)
        end

        it 'uses #properties as Netex DayType properties' do
          expect(day_type_attributes[:properties]).to be_kind_of(Array)
          expect(day_type_attributes[:properties]).not_to be_empty
        end
      end

      describe '#days_of_week' do
        before { allow(time_table).to receive(:periods) { Chouette::TimeTablePeriod.none } }

        %w{monday tuesday wednesday thursday friday saturday sunday}.each do |day|
          context "when the TimeTable includes #{day}" do
            before { allow(time_table).to receive(day.to_sym) { true } }

            it "inlucdes #{day.capitalize}" do
              expect(decorated_tt.days_of_week).to include(day.capitalize)
            end
          end
        end
      end

      describe '#exported_periods' do
        it 'should have one DayTypeAssignment & one OperatingPeriod for each period' do
          dats_count = decorated_tt.exported_periods.count {|r| r.is_a? Netex::DayTypeAssignment }
          ops_count = decorated_tt.exported_periods.count {|r| r.is_a? Netex::OperatingPeriod }

          expect(dats_count).to eq(time_table.periods.count)
          expect(ops_count).to eq(time_table.periods.count)
        end
      end

      describe '#exported_dates' do
        it 'should have have the same number of dates' do
          expect(time_table.dates.count).to eq(decorated_tt.exported_dates.count)
        end
      end
    end

    describe Export::NetexGeneric::PeriodDecorator do
      let(:time_table) { Chouette::TimeTable.new objectid: 'chouette:TimeTable:test:LOC' }

      let(:period) do
        Chouette::TimeTablePeriod.new period_start: Date.parse('2021-01-01'),
                                      period_end: Date.parse('2021-12-31'),
                                      time_table: time_table
      end
      let(:decorator) { Export::NetexGeneric::PeriodDecorator.new period, nil }

      describe "#operating_period_attributes" do
        subject { decorator.operating_period_attributes }

        it 'has a id with the OperatingPeriod type' do
          expect(subject[:id]).to include('OperatingPeriod')
        end

        it "uses the Period start date as NeTEx from date (the datetime is created by the Netex resource)" do
          is_expected.to include(from_date: period.period_start)
        end

        it "uses the Period end date as NeTEx to date (the datetime is created by the Netex resource)" do
          is_expected.to include(to_date: period.period_end)
        end
      end

      describe "#day_type_assignment_attributes" do
        subject { decorator.day_type_assignment_attributes }

        it 'has a id with the DayTypeAssignment type' do
          expect(subject[:id]).to include('DayTypeAssignment')
          expect(subject[:id]).to match(/p#{period.id}/)
        end
      end

    end

    describe Export::NetexGeneric::DateDecorator do
      let(:time_table) { Chouette::TimeTable.new objectid: 'chouette:TimeTable:test:LOC' }

      let(:date) do
        Chouette::TimeTableDate.new date: Date.parse('2021-01-01'), time_table: time_table
      end
      let(:decorator) { Export::NetexGeneric::DateDecorator.new date, nil }

      subject { decorator.day_type_assignment_attributes }

      it 'has a id with the DayTypeAssignment type' do
        expect(subject[:id]).to include('DayTypeAssignment')
        expect(subject[:id]).to match(/d#{date.id}/)
      end
    end

  end

  describe 'Organisation export' do

    describe Export::NetexGeneric::Organisations::Decorator do
      let(:organisation) { Organisation.new }

      describe "netex_resource" do

        subject(:resource) { described_class.new(organisation).netex_resource }

        describe '#id' do
          it 'uses Organisation\'s code' do
            is_expected.to have_attributes(id: organisation.code)
          end
        end

        describe '#name' do
          it 'uses Organisation\'s name' do
            is_expected.to have_attributes(name: organisation.name)
          end
        end

      end
    end
  end

  class MockNetexTarget

    def add(resource)
      resources << resource
    end
    alias << add

    def resources
      @resources ||= []
    end

  end

end
