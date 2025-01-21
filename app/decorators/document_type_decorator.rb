class DocumentTypeDecorator < Af83::Decorator
  decorates DocumentType

  set_scope { context[:workgroup] }

  create_action_link

  with_instance_decorator do |instance_decorator|
    instance_decorator.show_action_link
    instance_decorator.edit_action_link
    instance_decorator.destroy_action_link
  end
end
