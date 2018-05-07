RSpec.describe WorkgroupPolicy, type: :policy do

  let( :record ){ build_stubbed :workgroup }

  permissions :create? do
    it "should not allow for creation" do
      expect_it.not_to permit(user_context, record)
    end
  end

  permissions :update? do
    it "should not allow for update" do
      expect_it.not_to permit(user_context, record)
    end

    context "for the owner" do
      before do
        record.owner = user.organisation
      end

      it "should allow for update" do
        expect_it.to permit(user_context, record)
      end
    end
  end

  permissions :destroy? do
    it "should not allow for destroy" do
      expect_it.not_to permit(user_context, record)
    end

    context "for the owner" do
      before do
        record.owner = user.organisation
      end

      it "should not allow for destroy" do
        expect_it.not_to permit(user_context, record)
      end
    end
  end


end
