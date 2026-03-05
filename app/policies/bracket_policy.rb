class BracketPolicy < ApplicationPolicy
  def show?
    Current.tournament.started? || record.user == user
  end

  def create?
    !Current.tournament.started?
  end

  def update?
    !Current.tournament.started? && record.user == user
  end

  def destroy?
    !Current.tournament.started? && record.user == user
  end

  class Scope < Scope
    def resolve
      Current.tournament.started? ? scope.all : scope.where(user_id: user.id)
    end
  end
end
