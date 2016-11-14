class ReferentialCompaniesController < ChouetteController
  defaults :resource_class => Chouette::Company, :collection_name => 'companies', :instance_name => 'company'
  respond_to :html
  respond_to :xml
  respond_to :json
  respond_to :js, :only => :index

  belongs_to :referential, :parent_class => Referential

  def index
    index! do |format|
      format.html {
        if collection.out_of_bounds?
          redirect_to params.merge(:page => 1)
        end
      }
      build_breadcrumb :index
    end
  end

  protected

  def build_resource
    super.tap do |company|
      company.line_referential = referential.line_referential
    end
  end

  def collection
    @q = referential.workbench.companies.search(params[:q])
    @companies ||= @q.result(:distinct => true).order(:name).paginate(:page => params[:page])
  end

  def resource_url(company = nil)
    referential_company_path(referential, company || resource)
  end

  def collection_url
    referential_companies_path(referential)
  end

  def company_params
    params.require(:company).permit( :objectid, :object_version, :creation_time, :creator_id, :name, :short_name, :organizational_unit, :operating_department_name, :code, :phone, :fax, :email, :registration_number, :url, :time_zone )
  end
end
