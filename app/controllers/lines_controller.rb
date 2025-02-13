# frozen_string_literal: true

class LinesController < Chouette::LineReferentialController
  include ApplicationHelper

  defaults :resource_class => Chouette::Line

  # rubocop:disable Rails/LexicallyScopedActionFilter
  before_action :authorize_resource, except: %i[new create index show autocomplete]
  # rubocop:enable Rails/LexicallyScopedActionFilter

  respond_to :html, :xml, :json
  respond_to :js, :only => :index

  def autocomplete
    scope = line_referential.lines.referents

    query = 'unaccent(name) ILIKE unaccent(?) OR registration_number ILIKE ? OR objectid ILIKE ?'
    args = ["%#{params[:q]}%"] * 3

    @lines = scope.where(query, *args).limit(50)
  end

  def index
    if saved_search = saved_searches.find_by(id: params[:search_id])
      @search = saved_search.search
    end

    index! do |format|
      format.html {
        @lines = LineDecorator.decorate(
          collection,
          context: {
            workbench: workbench,
            line_referential: line_referential,
            # TODO Remove me ?
            current_organisation: current_organisation
          }
        )
      }
    end
  end

  def show
    show! do
      @line = @line.decorate(
        context: {
          workbench: workbench,
          line_referential: line_referential,
          current_organisation: current_organisation
        }
      )
    end
  end

  def new
    build_resource
    super
  end

  # overwrite inherited resources to use delete instead of destroy
  # foreign keys will propagate deletion)
  def destroy_resource(object)
    object.delete
  end

  def name_filter
    respond_to do |format|
      format.json { render :json => filtered_lines_maps}
    end
  end

  def saved_searches
    @saved_searches ||= workbench.saved_searches.for(Search::Line)
  end

  protected

  def scope
    parent.lines
  end

  def search
    @search ||= Search::Line.from_params(params, workbench: workbench)
  end

  def collection
    @collection ||= search.search scope
  end

  delegate :workgroup, to: :workbench, allow_nil: true

  private

  def line_params
    return @line_params if @line_params

    out = params.require(:line).permit(
      :activated,
      :active_from,
      :active_until,
      :transport_mode,
      :network_id,
      :company_id,
      :objectid,
      :object_version,
      :name,
      :number,
      :published_name,
      :registration_number,
      :comment,
      :line_provider_id,
      :mobility_impaired_accessibility,
      :wheelchair_accessibility,
      :step_free_accessibility,
      :escalator_free_accessibility,
      :lift_free_accessibility,
      :audible_signals_availability,
      :visual_signs_availability,
      :accessibility_limitation_description,
      :flexible_line_type,
      :booking_arrangement_id,
      :url,
      :color,
      :text_color,
      :transport_submode,
      :seasonal,
      :line_notice_ids,
      :is_referent,
      :referent_id,
      :secondary_company_ids => [],
      footnotes_attributes: [:code, :label, :_destroy, :id],
      codes_attributes: [:id, :code_space_id, :value, :_destroy],
    )
    out[:secondary_company_ids] = (out[:secondary_company_ids] || []).select(&:present?)
    out
    @line_params = out
  end
end
