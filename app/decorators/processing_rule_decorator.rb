# frozen_string_literal: true

class ProcessingRuleDecorator < Af83::Decorator
  decorates ProcessingRule::Workbench

  set_scope { context[:workbench] }

  create_action_link do |l|
    l.content { I18n.t('processing_rule/workbenches.actions.new') }
  end

  with_instance_decorator(&:crud)

  define_instance_method :name do
    return unless processable

    I18n.t(
      'processing_rule/workbenches.name',
      processable_type: processable_type.text,
      operation_step: operation_step.text,
      processable_name: processable.name
    )
  end
end
