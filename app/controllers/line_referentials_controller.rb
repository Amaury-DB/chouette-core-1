class LineReferentialsController < ChouetteController
  belongs_to :workbench
  defaults :resource_class => LineReferential, singleton: true

  def show
    show! do
      @line_referential = LineReferentialDecorator.decorate(@line_referential)
    end
  end

  def sync
    authorize resource, :synchronize?
    @sync = resource.line_referential_syncs.build
    if @sync.save
      flash[:notice] = t('notice.line_referential_sync.created')
    else
      flash[:error] = @sync.errors.full_messages.to_sentence
    end
    redirect_to [ @workbench, :line_referential ]
  end

  protected

  def line_referential_params
    params.require(:line_referential).permit(:sync_interval)
  end

end
