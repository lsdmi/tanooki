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

  test 'experience_to_sentence returns correct sentence for 0' do
    assert_equal 'Відсутній', experience_to_sentence(0)
  end

  test 'experience_to_sentence returns correct sentence for rate in 1..20 range' do
    assert_equal 'Початківець', experience_to_sentence(15)
  end

  test 'experience_to_sentence returns correct sentence for rate in 21..50 range' do
    assert_equal 'Вояк', experience_to_sentence(45)
  end

  test 'experience_to_sentence returns correct sentence for rate in 51..90 range' do
    assert_equal 'Ветеран', experience_to_sentence(70)
  end

  test 'experience_to_sentence returns correct sentence for rate in 91..Float::INFINITY range' do
    assert_equal 'Незборний', experience_to_sentence(100)
  end
end
