class AutocompleteController < ChouetteController

  ##############
  # Line scope #
  ##############
  def lines
    @lines = line_scope.lines.order(:name).by_text(text)
  end

  def companies
    @companies = line_scope.companies.order(:name).by_text(text)
  end

  def line_providers
    @line_providers = line_scope.line_providers.order(:short_name).by_text(text)
  end

  ##################
  # StopArea scope #
  ##################

  # def autocomplete
  #   scope = stop_area_referential.stop_areas.where(deleted_at: nil)
  #   scope = scope.referent_only if params[:referent_only]
  #   args  = [].tap{|arg| 4.times{arg << "%#{params[:q]}%"}}
  #   @stop_areas = scope.where("unaccent(name) ILIKE unaccent(?) OR unaccent(city_name) ILIKE unaccent(?) OR registration_number ILIKE ? OR objectid ILIKE ?", *args).limit(50)
  #   @stop_areas
  # end
  def stop_areas
    @stop_areas = stop_area_scope.stop_areas.order(:name).by_text(text)
  end

  def parent_stop_areas
    @stop_areas = stop_area_scope.stop_areas.all_parents.order(:name).by_text(text)
  end

  # def autocomplete
  # -    scope = policy_scope(parent.stop_area_providers)
  # -    args  = [].tap{|arg| 2.times{arg << "%#{params[:q]}%"}}
  # -    @stop_area_providers = scope.where("unaccent(name) ILIKE unaccent(?) OR objectid ILIKE ?", *args).limit(50)
  # -    @stop_area_providers
  # -  end
  def stop_area_providers
    @stop_area_providers = stop_area_scope.stop_area_providers.order(:name).by_text(text)
  end

  protected

  def text
    @text = params[:q]
  end

  def stop_area_scope
    stop_area_referential || workbench || referential
  end

  def line_scope
    line_referential || workbench || referential
  end

  def stop_area_referential
    @stop_area_referential ||= current_organisation.workgroups.find(params[:workgroup_id]).stop_area_referential if params[:workgroup_id]
  end

  def line_referential
    @line_referential ||= current_organisation.workgroups.find(params[:workgroup_id]).line_referential if params[:workgroup_id]
  end

  def workbench
    @workbench ||= current_organisation.workbenches.find(params[:workbench_id]) if params[:workbench_id]
  end

  def referential
    @referential ||= current_organisation.find_referential(params[:referential_id]) if params[:referential_id]
  end
end
