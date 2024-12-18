# frozen_string_literal: true

class AccessibilityAssessmentsController < Chouette::TopologicReferentialController
  defaults resource_class: AccessibilityAssessment

  # rubocop:disable Rails/LexicallyScopedActionFilter
  before_action :authorize_resource, except: %i[new create index show autocomplete]
  # rubocop:enable Rails/LexicallyScopedActionFilter

  respond_to :html
  respond_to :json

  def autocomplete
    accessibility_assessments = scope.order(:name).limit(50)

    accessibility_assessments = accessibility_assessments.where(
      'unaccent(name) ILIKE unaccent(?)', "%#{params[:q]}%"
    ) if params[:q].present?

    @accessibility_assessments = accessibility_assessments
  end

  def index
    index! do |format|
      format.html do
        @accessibility_assessments = AccessibilityAssessmentDecorator.decorate(
          collection,
          context: {
            workbench: workbench
          }
        )
      end
    end
  end

  protected

  alias accessibility_assessment resource

  def scope
    @scope ||= workbench.shape_referential.accessibility_assessments
  end

  def resource
    super.decorate(context: { workbench: workbench })
  end

  def build_resource
    super.decorate(context: { workbench: workbench })
  end

  def collection
    @accessibility_assessments = scope.paginate(page: params[:page], per_page: 30)
  end

  private

  def accessibility_assessment_params
    params.require(:accessibility_assessment).permit(
      :name,
      :mobility_impaired_accessibility,
      :wheelchair_accessibility,
      :step_free_accessibility,
      :escalator_free_accessibility,
      :lift_free_accessibility,
      :audible_signals_availability,
      :visual_signs_availability,
      :accessibility_limitation_description,
      codes_attributes: [:id, :code_space_id, :value, :_destroy],
    )
  end
end
