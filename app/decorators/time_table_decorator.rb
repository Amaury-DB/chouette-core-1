class TimeTableDecorator < AF83::Decorator
  decorates Chouette::TimeTable

  create_action_link if: ->{ h.policy(Chouette::TimeTable).create? && context[:referential].organisation == h.current_organisation } do |l|
    l.href { h.new_referential_time_table_path(context[:referential]) }
  end

  with_instance_decorator do |instance_decorator|
    instance_decorator.set_scope { context[:referential] }
    instance_decorator.crud

    instance_decorator.action_link policy: :actualize, if: ->{ object.calendar }, secondary: true do |l|
      l.content t('actions.actualize')
      l.href do
         h.actualize_referential_time_table_path(
          context[:referential],
          object
        )
      end
      l.method :post
    end

    instance_decorator.action_link policy: :edit, secondary: true do |l|
      l.content t('actions.combine')
      l.href do
        h.new_referential_time_table_time_table_combination_path(
          context[:referential],
          object
        )
      end
    end

    instance_decorator.action_link policy: :duplicate, secondary: true do |l|
      l.content t('actions.duplicate')
      l.href do
        h.duplicate_referential_time_table_path(
          context[:referential],
          object
        )
      end
      l.icon :clone
    end
  end
end
