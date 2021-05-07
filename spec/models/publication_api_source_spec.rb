RSpec.describe PublicationApiSource, type: :model do
  it { should belong_to :publication_api }
  it { should belong_to :publication }

  let(:line) { create :line }
  let(:public_url) {"http://www.montest.com/api/v1/datas/test"}

  let(:publication_gtfs) {create :publication, :with_gtfs}
  let(:publication_api_source_gtfs) { create(:publication_api_source, publication: publication_gtfs, export: create(:gtfs_export)) }

  let(:publication_setup_gtfs_line) { create :publication_setup_gtfs, publish_per_line: true, export_options: { duration: 200, prefer_referent_stop_area: false, ignore_single_stop_station: false, line_ids: [line.id] } }
  let(:publication_gtfs_line) { create :publication, publication_setup: publication_setup_gtfs_line }
  let(:publication_api_source_gtfs_line) { create(:publication_api_source, publication: publication_gtfs_line, export: create(:gtfs_export, options: { duration: 200, prefer_referent_stop_area: false, ignore_single_stop_station: false, line_ids: [line.id] })) }

  let(:publication_idfm_netex_full) {create :publication, :with_idfm_netex_full}
  let(:publication_api_source_idfm_netex_full) { create(:publication_api_source, publication: publication_idfm_netex_full, export: create(:idfm_netex_export_full)) }

  let(:publication_netex_generic_idfm_line) {create :publication, :with_netex_generic}

  let(:publication_api_source) { create(:publication_api_source, publication: publication_gtfs, export: nil) }

  context '#public_url' do
    it 'should generate for each format the good public url' do
      allow_any_instance_of(PublicationApi).to receive(:public_url).and_return public_url

      expect(publication_api_source.public_url).to be_nil

      expect(publication_api_source_gtfs.public_url).to eq "#{public_url}/gtfs.zip"
      expect(publication_api_source_gtfs_line.public_url).to eq "#{public_url}/lines/#{line.registration_number}-gtfs.zip"

      expect(publication_api_source_idfm_netex_full.public_url).to eq "#{public_url}/netex.zip"
    end
  end

  context '#public_url_filename' do
    it 'should generate for each format the good public url filename' do
      allow_any_instance_of(PublicationApi).to receive(:public_url).and_return public_url

      expect(publication_api_source.public_url_filename).to be_nil

      expect(publication_api_source_gtfs.public_url_filename).to eq "test.gtfs.zip"
      expect(publication_api_source_gtfs_line.public_url_filename).to eq "#{line.registration_number}-gtfs.zip"

      expect(publication_api_source_idfm_netex_full.public_url_filename).to eq "test.netex.zip"
    end
  end
end
