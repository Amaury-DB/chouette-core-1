RSpec.describe Control::List do
  let(:context) do
    Chouette.create { workbench }
  end

  subject(:control_list) do
    context.workbench.control_lists.create! name: "Test"
  end

  it { is_expected.to validate_presence_of(:name) }
  it { is_expected.to belong_to(:workbench).required }

  describe ".controls"do
    before do
      3.times do |n|
        control = Control::Dummy.new(name: "Test #{n}")
        control_list.controls << control
      end
    end

    subject { control_list.controls }

    it "store an ordered list" do
      ordered_instances = [
        an_object_having_attributes(position: 1),
        an_object_having_attributes(position: 2),
        an_object_having_attributes(position: 3)
      ]
      is_expected.to match_array(ordered_instances)
    end

    it "store Control instances (not base model)" do
      is_expected.to all(be_an_instance_of(Control::Dummy))
    end

    it "delete controls with list" do
      expect { control_list.destroy }.to change { Control::Base.count }.by(-3)
    end
  end
end

RSpec.describe Control::Base do
  subject { Control::Dummy.new }
  it { is_expected.to belong_to(:control_list).optional }

end
