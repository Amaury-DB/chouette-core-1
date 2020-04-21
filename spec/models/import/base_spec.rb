RSpec.describe Import::Base, type: :model do
  it { should belong_to(:referential) }
  it { should belong_to(:workbench) }
  it { should belong_to(:parent) }

  it { should enumerize(:status).in("aborted", "canceled", "failed", "new", "pending", "running", "successful", "warning") }

  it { should validate_presence_of(:workbench) }
  it { should validate_presence_of(:creator) }

  describe ".purge_imports" do
    let(:workbench) { create(:workbench) }
    let(:other_workbench) { create(:workbench) }

    it "removes files from imports older than 60 days" do
      file_purgeable = Timecop.freeze(60.days.ago) do
        create(:workbench_import, workbench: workbench)
      end

      other_file_purgeable = Timecop.freeze(60.days.ago) do
        create( :workbench_import, workbench: other_workbench )
      end

      Import::Workbench.new(workbench: workbench).purge_imports

      expect(file_purgeable.reload.file_url).to be_nil
      expect(other_file_purgeable.reload.file_url).not_to be_nil
    end

    it "removes imports older than 90 days" do
      old_import = Timecop.freeze(90.days.ago) do
        create(:workbench_import, workbench: workbench)
      end

      other_old_import = Timecop.freeze(90.days.ago) do
        create(:workbench_import, workbench: other_workbench)
      end

      expect { Import::Workbench.new(workbench: workbench).purge_imports }.to change {
        old_import.workbench.imports.purgeable.count
      }.from(1).to(0)

      expect { Import::Workbench.new(workbench: workbench).purge_imports }.not_to change {
        old_import.workbench.imports.purgeable.count
      }
    end
  end

  context "#user_file" do

    before do
      subject.name = "Dummy Import Example"
    end

    it 'uses a parameterized version of the Import name as base name' do
      expect(subject.user_file.basename).to eq("dummy-import-example")
    end

    it 'uses the Import content_type' do
      expect(subject.user_file.content_type).to eq(subject.content_type)
    end

    it 'uses the Import file_extension' do
      expect(subject.user_file.extension).to eq(subject.send(:file_extension))
    end

  end

end
