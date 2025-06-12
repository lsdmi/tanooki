# frozen_string_literal: true

class FictionPolicy
  attr_reader :user, :fiction

  def initialize(user, fiction)
    @user = user
    @fiction = fiction
  end

  def edit?
    user.admin? || user.fictions.include?(fiction)
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
