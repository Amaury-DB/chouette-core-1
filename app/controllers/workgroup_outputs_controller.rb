class WorkgroupOutputsController < ChouetteController
  respond_to :html, only: [:show]
  defaults resource_class: Workgroup

  def show
    @workgroup = current_organisation.workgroups.find params[:workgroup_id]
    @aggregates = @workgroup.aggregates.order("created_at desc").paginate(page: params[:page], per_page: 10)
  end
end
