class PointOfInterestCategoryDecorator < AF83::Decorator
  decorates PointOfInterest::Category

  set_scope { [context[:workbench], :shape_referential] }

  create_action_link

  action_link(on: %i[index], secondary: :index) do |l|
    l.content { t('point_of_interest_categories.actions.show_poi') }
    l.href { h.workbench_shape_referential_point_of_interests_path }
  end

  with_instance_decorator do |instance_decorator|
    instance_decorator.show_action_link
    instance_decorator.edit_action_link
    instance_decorator.destroy_action_link
  end

  def policy_parent
    context[:workbench].default_shape_provider
  end
end
