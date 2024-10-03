# frozen_string_literal: true

class WorkgroupImportsController < Chouette::WorkgroupController
  include Downloadable
  include ImportMessages

  def self.controller_path
    'imports'
  end

  defaults resource_class: Import::Base, collection_name: 'imports', instance_name: 'import'

  # rubocop:disable Rails/LexicallyScopedActionFilter
  before_action :authorize_resource, except: %i[new create index show download messages]
  # rubocop:enable Rails/LexicallyScopedActionFilter

  respond_to :json, :html

  def download
    prepare_for_download resource
    send_file resource.file.path, filename: resource.user_file.name, type: resource.user_file.content_type
  end

  def show
    @import = resource.decorate(context: { parent: parent })
    respond_to do |format|
      format.html do
        @workbench = default_workbench
      end
      format.json do
        fragment = render_to_string(partial: "imports/#{@import.short_type}", formats: :html)
        render json: { fragment: fragment }
      end
    end
  end

  def index # rubocop:disable Metrics/AbcSize,Metrics/MethodLength
    if (saved_search = saved_searches.find_by(id: params[:search_id]))
      @search = saved_search.search
    end

    index! do |format|
      format.html do
        @chart = @search.chart(scope) if @search.graphical?

        unless @chart
          @contextual_cols = []
          @contextual_cols << TableBuilderHelper::Column.new(
            key: :workbench,
            name: Workbench.ts.capitalize,
            attribute: proc { |n| n.workbench.name },
            link_to: lambda do |import|
              import.workbench
            end
          )
          @imports = decorate_collection(collection)
        end
      end
    end
  end

  def saved_searches
    @saved_searches ||= workgroup.saved_searches.for(::Search::WorkgroupImport)
  end

  protected

  # rubocop:disable Naming/MemoizedInstanceVariableName
  def resource
    @import ||= parent.imports.find(params[:id])
  end
  # rubocop:enable Naming/MemoizedInstanceVariableName

  def scope
    parent.imports.where(type: 'Import::Workbench')
  end

  def search
    @search ||= ::Search::WorkgroupImport.from_params(params, workgroup: workgroup)
  end

  def collection
    @collection ||= search.search(scope)
  end

  def decorate_collection(imports)
    ImportDecorator.decorate(
      imports,
      context: {
        parent: parent
      }
    )
  end
end
