class BookPolicy < ApplicationPolicy
  def index?
    true
  end

  def show?
    true
  end

  def create?
    user.present?
  end

  def update?
    owns_record?
  end

  def destroy?
    owns_record?
  end

  class Scope < ApplicationPolicy::Scope
    def resolve
      scope.all
    end
  end

  private

  def owns_record?
    user.present? && record.user_id == user.id
  end
end
