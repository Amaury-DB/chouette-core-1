# frozen_string_literal: true

class StopAreaDecorator < Af83::Decorator
  include DocumentableDecorator

  decorates Chouette::StopArea

  set_scope { [ context[:workbench], :stop_area_referential ] }

  create_action_link do |l|
    l.content { I18n.t('stop_areas.actions.new') }
  end

  with_instance_decorator do |instance_decorator|
    instance_decorator.crud
  end

  define_instance_method :waiting_time_text do
    return '-' if [nil, 0].include? waiting_time
    I18n.t('stop_areas.waiting_time_format', value: waiting_time)
  end

  define_instance_method :human_status do
    I18n.t(status, scope: 'activerecord.attributes.stop_area')
  end

  define_instance_method :codes do
    object.codes.joins(:code_space).order('code_spaces.short_name ASC')
  end

  def policy_parent
    context[:workbench].default_stop_area_provider
  end
end
