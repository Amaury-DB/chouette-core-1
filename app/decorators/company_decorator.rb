class CompanyDecorator < AF83::Decorator
  decorates Chouette::Company

  set_scope { [ context[:workbench], :line_referential ] }

  create_action_link do |l|
    l.content { h.t('companies.actions.new') }
  end

  with_instance_decorator do |instance_decorator|
    instance_decorator.crud
  end
end
