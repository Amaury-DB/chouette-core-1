# frozen_string_literal: true

class Fare::ZoneDecorator < Af83::Decorator
  decorates Fare::Zone

  set_scope { context[:workbench] }

  create_action_link

  with_instance_decorator do |instance_decorator|
    instance_decorator.crud
  end

  def policy_parent
    context[:workbench].default_fare_provider
  end
end
