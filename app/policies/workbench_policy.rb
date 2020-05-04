class WorkbenchPolicy < ApplicationPolicy
  class Scope < Scope
    def resolve
      scope
    end
  end

  def show?
    user.organisation_id == record.organisation_id
  end

  def update?
    user.has_permission?('workbenches.update')
  end
end
