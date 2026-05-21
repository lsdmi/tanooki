# frozen_string_literal: true

# Authorization rules for fiction create, edit, update, and destroy.
class FictionPolicy
  attr_reader :user, :fiction

  def initialize(user, fiction)
    @user = user
    @fiction = fiction
  end

  def edit?
    user.manages_fiction?(fiction)
  end

  def update?
    edit?
  end

  def destroy?
    edit?
  end

  def create?
    user.admin? || user.scanlators.any?
  end
end
