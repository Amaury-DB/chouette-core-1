class StopAreaReferentialDecorator < AF83::Decorator
  decorates StopAreaReferential

  with_instance_decorator do |instance_decorator|

    instance_decorator.action_link policy: :synchronize, primary: :show do |l|
      l.content t('actions.sync')
      l.href { h. sync_stop_area_referential_path(object.id) }
      l.method :post
    end
    
  end
end
