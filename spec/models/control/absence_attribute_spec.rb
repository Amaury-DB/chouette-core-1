# frozen_string_literal: true

RSpec.describe Control::AbsenceAttribute do
  it 'should be one of the available Control' do
    expect(Control.available).to include(described_class)
  end

  describe Control::AbsenceAttribute::Run do
    it { should validate_presence_of :target_model }
    it { should validate_presence_of :target_attribute }
    it do
      should enumerize(:target_model).in(
        %w[
          Line
          StopArea
          Entrance
          PointOfInterest
          Route
          JourneyPattern
          VehicleJourney
          Shape
          Company
          Document
          Network
          ConnectionLink
        ]
      )
    end

    it 'should validate_presences of :model_attribute' do
      valid_control_run = described_class.new target_model: 'Line', target_attribute: 'name'

      valid_control_run.valid?

      expect(valid_control_run.model_attribute).to be
      expect(valid_control_run.errors.details[:model_attribute]).to be_empty

      invalid_control_run = described_class.new target_model: 'Line', target_attribute: 'names'

      invalid_control_run.valid?

      expect(invalid_control_run.model_attribute).to be_nil
      expect(invalid_control_run.errors.details[:model_attribute]).not_to be_empty
    end

    describe '#candidate_target_attributes' do
      subject { described_class.new.candidate_target_attributes }

      it 'does not cause error' do
        expect(Rails.logger).not_to receive(:error)
        subject
      end
    end

    let(:control_list_run) do
      Control::List::Run.create referential: context.referential, workbench: context.workbench
    end

    let(:control_run) do
      described_class.create(
        control_list_run: control_list_run,
        criticity: 'warning',
        options: { target_model: target_model, target_attribute: target_attribute },
        position: 0
      )
    end

    describe '#run' do
      subject { control_run.run }

      let(:context) do
        Chouette.create do
          company
          network
          stop_area :first
          stop_area :middle
          stop_area :last
          shape :shape
          referential do
            route stop_areas: [:first, :middle, :last] do
              journey_pattern shape: :shape
            end
          end
        end
      end

      let(:referential) { context.referential }

      let(:expected_message) do
        an_object_having_attributes({
          source: source,
          criticity: 'warning',
          message_attributes: {'name' => attribute_name}
        })
      end

      before do
        referential.switch
      end

      describe 'JourneyPattern' do
        let(:journey_pattern) { context.journey_pattern }
        let(:source) { journey_pattern }
        let(:attribute_name) { journey_pattern.name }
        let(:target_model) { 'JourneyPattern' }
        let(:target_attribute) { 'published_name' }

        context 'when name is present' do
          before { journey_pattern.update published_name: 'Test' }

          it 'should create a warning message' do
            subject

            expect(control_run.control_messages).to include(expected_message)
          end
        end
      end

      describe 'Line' do
        let(:company) { context.company }
        let(:network) { context.network }
        let(:line) { referential.lines.first }
        let(:source) { line }
        let(:attribute_name) { line.name }
        let(:target_model) { 'Line' }

        describe '#published_name' do
          let(:target_attribute) { 'published_name'}

          context 'when value is present' do
            before { line.update published_name: 'Test' }

            it 'should create warning message' do
              subject

              expect(control_run.control_messages).to include(expected_message)
            end
          end
        end

        describe '#number' do
          let(:target_model) { 'Line' }
          let(:target_attribute) { 'number'}

          context 'when value is present' do
            before { line.update number: 'Test' }

            it 'should create warning message' do
              subject

              expect(control_run.control_messages).to include(expected_message)
            end
          end
        end

        describe '#url' do
          let(:target_attribute) { 'url'}

          context 'when value is present' do
            before { line.update url: 'test.com' }

            it 'should create warning message' do
              subject

              expect(control_run.control_messages).to include(expected_message)
            end
          end
        end

        describe '#transport_mode' do
          let(:target_model) { 'Line' }
          let(:target_attribute) { 'transport_mode'}

          context 'when value is present' do
            before { line.update transport_mode: 'bus' }

            it 'should create warning message' do
              subject

              expect(control_run.control_messages).to include(expected_message)
            end
          end
        end

        describe '#color' do
          let(:target_model) { 'Line' }
          let(:target_attribute) { 'color'}

          context 'when value is present' do
            before { line.update color: 'CD5C5C' }

            it 'should create warning message' do
              subject

              expect(control_run.control_messages).to include(expected_message)
            end
          end
        end

        describe '#text_color' do
          let(:target_model) { 'Line' }
          let(:target_attribute) { 'text_color'}

          context 'when value is present' do
            before { line.update text_color: 'CD5C5C' }

            it 'should create warning message' do
              subject

              expect(control_run.control_messages).to include(expected_message)
            end
          end
        end
      end

      describe 'StopArea' do
        let(:company) { context.company }
        let(:network) { context.network }
        let(:stop_area) { context.stop_area(:first).reload }
        let(:source) { stop_area }
        let(:attribute_name) { stop_area.name }
        let(:target_model) { 'StopArea' }

        describe '#public_code' do
          let(:target_attribute) { 'public_code' }

          context 'when value is present' do
            before { stop_area.update public_code: 'Test' }

            it 'should create warning message' do
              subject

              expect(control_run.control_messages).to include(expected_message)
            end
          end
        end

        describe '#url' do
          let(:target_attribute) { 'url'}

          context 'when value is present' do
            before { stop_area.update url: 'test.com' }

            it 'should create warning message' do
              subject

              expect(control_run.control_messages).to include(expected_message)
            end
          end
        end

        describe '#coordinates' do
          let(:target_attribute) { 'coordinates' }

          context 'when value is present' do
            before { stop_area.update longitude: 48.01, latitude: 12.02 }

            it 'should create warning message' do
              subject

              expect(control_run.control_messages).to include(expected_message)
            end
          end
        end

        describe '#compass_bearing' do
          let(:target_attribute) { 'compass_bearing' }

          context 'when value is present' do
            before { stop_area.update compass_bearing: 120 }

            it 'should create warning message' do
              subject

              expect(control_run.control_messages).to include(expected_message)
            end
          end
        end

        describe '#street_name' do
          let(:target_attribute) { 'street_name' }

          context 'when value is present' do
            before { stop_area.update street_name: 'Test' }

            it 'should create warning message' do
              subject

              expect(control_run.control_messages).to include(expected_message)
            end
          end
        end

        describe '#zip_code' do
          let(:target_attribute) { 'zip_code' }

          context 'when value is present' do
            before { stop_area.update zip_code: '44300' }

            it 'should create warning message' do
              subject

              expect(control_run.control_messages).to include(expected_message)
            end
          end
        end

        describe '#city_name' do
          let(:target_attribute) { 'city_name' }

          context 'when value is present' do
            before { stop_area.update city_name: 'Nantes' }

            it 'should create warning message' do
              subject

              expect(control_run.control_messages).to include(expected_message)
            end
          end
        end

        describe '#postal_region' do
          let(:target_attribute) { 'postal_region' }

          context 'when value is present' do
            before { stop_area.update postal_region: 'Test' }

            it 'should create warning message' do
              subject

              expect(control_run.control_messages).to include(expected_message)
            end
          end
        end

        describe '#country_code' do
          let(:target_attribute) { 'country_code' }

          context 'when value is present' do
            before { stop_area.update country_code: 'FR' }

            it 'should create warning message' do
              subject

              expect(control_run.control_messages).to include(expected_message)
            end
          end
        end

        describe '#time_zone' do
          let(:target_attribute) { 'time_zone' }

          context 'when value is present' do
            before { stop_area.update time_zone: 'America/Los_Angeles' }

            it 'should create warning message' do
              subject

              expect(control_run.control_messages).to include(expected_message)
            end
          end
        end

        describe '#waiting_time' do
          let(:target_attribute) { 'waiting_time' }

          context 'when value is present' do
            before { stop_area.update waiting_time: 3 }

            it 'should create warning message' do
              subject

              expect(control_run.control_messages).to include(expected_message)
            end
          end
        end
      end

      describe 'VehicleJourney' do
        let(:company) {context.company}
        let(:vehicle_journey) { create(:vehicle_journey) }
        let(:source) { vehicle_journey }
        let(:attribute_name) { vehicle_journey.id }
        let(:target_model) { 'VehicleJourney' }

        describe '#transport_mode' do
          let(:target_attribute) { 'transport_mode'}

          context 'when value is present' do
            before { vehicle_journey.update transport_mode: 'bus' }

            it 'should create warning message' do
              subject

              expect(control_run.control_messages).to include(expected_message)
            end
          end
        end

        describe '#published_journey_identifier' do
          let(:target_attribute) { 'published_journey_identifier'}

          context 'when value is present' do
            before { vehicle_journey.update published_journey_identifier: 'Test' }

            it 'should create warning message' do
              subject

              expect(control_run.control_messages).to include(expected_message)
            end
          end
        end

        describe '#published_journey_name' do
          let(:target_attribute) { 'published_journey_name'}

          context 'when value is present' do
            before { vehicle_journey.update published_journey_name: 'Test' }

            it 'should create warning message' do
              subject

              expect(control_run.control_messages).to include(expected_message)
            end
          end
        end
      end

      describe 'Company' do
        let(:company) {context.company}
        let(:line) { context.referential.lines.first }
        let(:source) { company }
        let(:target_model) { 'Company' }
        let(:attribute_name) { company.name }

        before :each do
          line.update company: company
        end

        [ 'short_name', 'house_number', 'street', 'address_line_1', 'address_line_2',
          'town', 'postcode', 'postcode_extension', 'default_contact_name', 'code'  ].each do |attr_name|
          describe "##{attr_name}" do
            let(:target_attribute) { attr_name}

            context 'when value is present' do
              before { company.update({attr_name.to_sym => 'Test'}) }

              it 'should create warning message' do
                subject

                expect(control_run.control_messages).to include(expected_message)
              end
            end
          end
        end

        describe '#country_code' do
          let(:target_attribute) { 'country_code' }

          context 'when value is present' do
            before { company.update country_code: 'Test' }

            it 'should create warning message' do
              subject

              expect(control_run.control_messages).to include(expected_message)
            end
          end
        end

        describe '#time_zone' do
          let(:target_attribute) { 'time_zone' }

          context 'when value is present' do
            before { company.update time_zone: 'Test' }

            it 'should create warning message' do
              subject

              expect(control_run.control_messages).to include(expected_message)
            end
          end
        end

        describe '#default_language' do
          let(:target_attribute) { 'default_language' }

          context 'when value is present' do
            before { company.update default_language: 'Test' }

            it 'should create warning message' do
              subject

              expect(control_run.control_messages).to include(expected_message)
            end
          end
        end

        describe '#default_contact_url' do
          let(:target_attribute) { 'default_contact_url' }

          context 'when value is present' do
            before { company.update default_contact_url: 'Test' }

            it 'should create warning message' do
              subject

              expect(control_run.control_messages).to include(expected_message)
            end
          end
        end

        describe '#default_contact_phone' do
          let(:target_attribute) { 'default_contact_phone' }

          context 'when value is present' do
            before { company.update default_contact_phone: 'Test' }

            it 'should create warning message' do
              subject

              expect(control_run.control_messages).to include(expected_message)
            end
          end
        end

        describe '#default_contact_email' do
          let(:target_attribute) { 'default_contact_email' }

          context 'when value is present' do
            before { company.update default_contact_email: 'Test' }

            it 'should create warning message' do
              subject

              expect(control_run.control_messages).to include(expected_message)
            end
          end
        end
      end
    end
  end
end
