# frozen_string_literal: true

module Policy
  class Workbench < Base
    authorize_by Strategy::Permission

    protected

    def _create?(resource_class) # rubocop:disable Metrics/MethodLength
      if resource_class == ::Workbench::Sharing
        !resource.pending?
      else
        [
          ::Referential,
          ::DocumentProvider,
          ::Calendar,
          ::Control::List,
          ::Control::List::Run,
          ::Macro::List,
          ::Macro::List::Run,
          ::ProcessingRule::Workbench,
          ::NotificationRule,
          ::Fare::Provider,
          ::Contract,
          ::Import::Base,
          ::Export::Base,
          ::ApiKey,
          ::Merge,
          ::Source,
          ::Sequence
        ].include?(resource_class)
      end
    end

    def _update?
      true
    end

    # TODO Enable workbench deletion / creation from workgroup admin section
    # def _destroy?
    #   update?
    # end
  end
end
