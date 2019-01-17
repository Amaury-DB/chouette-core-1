class UserDecorator < AF83::Decorator
  decorates User

  set_scope { [:organisation] }

  define_instance_method :profile_i18n do
    "permissions.profiles.#{object.profile}.name".t
  end

  define_instance_method :state_i18n do
    "users.states.#{object.state}".t
  end

  with_instance_decorator do |instance_decorator|
    instance_decorator.show_action_link
    instance_decorator.edit_action_link
    instance_decorator.destroy_action_link

    instance_decorator.action_link policy: :block, secondary: true do |l|
      l.content t('users.actions.block')
      l.confirm t('users.actions.block_confirm')
      l.href do
        h.block_organisation_user_path(
          object
        )
      end
      l.method :put
    end

    instance_decorator.action_link policy: :unblock, secondary: true do |l|
      l.content t('users.actions.unblock')
      l.confirm t('users.actions.unblock_confirm')
      l.href do
        h.unblock_organisation_user_path(
          object
        )
      end
      l.method :put
    end

    instance_decorator.action_link policy: :reinvite, secondary: true do |l|
      l.content t('users.actions.reinvite')
      l.confirm t('users.actions.reinvite_confirm')
      l.href do
        h.reinvite_organisation_user_path(
          object
        )
      end
      l.method :put
    end

    instance_decorator.action_link policy: :reset_password, secondary: true do |l|
      l.content t('users.actions.reset_password')
      l.confirm t('users.actions.reset_password_confirm')
      l.href do
        h.reset_password_organisation_user_path(
          object
        )
      end
      l.method :put
    end
  end
end
