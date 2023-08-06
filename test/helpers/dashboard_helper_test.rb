# frozen_string_literal: true

require 'test_helper'

class DashboardHelperTest < ActionView::TestCase
  include DashboardHelper

  test 'users size is 1 and user matches' do
    user = User.new(id: 1, admin: false)
    users = [user]

    assert delete_permissions?(users, user)
  end

  test 'user is admin' do
    user = User.new(id: 1, admin: true)
    users = [User.new(id: 2, admin: false)]

    assert delete_permissions?(users, user)
  end

  test 'users size is not 1 and user is not admin' do
    user = User.new(id: 1, admin: false)
    users = [User.new(id: 2, admin: false), user]

    refute delete_permissions?(users, user)
  end

  test "users size is 1 but user doesn't match" do
    user = User.new(id: 1, admin: false)
    users = [User.new(id: 2, admin: false)]

    refute delete_permissions?(users, user)
  end
end
