require 'spec_helper'

describe "/stop_areas/index", :type => :view do

  let!(:stop_area_referential) { assign :stop_area_referential, create(:stop_area_referential) }
  let!(:stop_areas) { assign :stop_areas, Array.new(2) { create(:stop_area, stop_area_referential: stop_area_referential) }.paginate }
  let!(:q) { assign :q, Ransack::Search.new(Chouette::StopArea) }

  before :each do
    allow(view).to receive(:link_with_search).and_return("#")
  end

  # it "should render a show link for each group" do
  #   render
  #   stop_areas.each do |stop_area|
  #     expect(rendered).to have_selector(".stop_area a[href='#{view.stop_area_referential_stop_area_path(stop_area_referential, stop_area)}']", :text => stop_area.name)
  #   end
  # end
  #
  # it "should render a link to create a new group" do
  #   render
  #   expect(view.content_for(:sidebar)).to have_selector(".actions a[href='#{new_stop_area_referential_stop_area_path(stop_area_referential)}']")
  # end

end
