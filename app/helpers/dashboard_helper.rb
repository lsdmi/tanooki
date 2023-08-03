# frozen_string_literal: true

module DashboardHelper
  def delete_permissions?(users, user)
    (users.size == 1 && users.first == user) || user.admin?
  end
end
