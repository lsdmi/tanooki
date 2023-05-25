# frozen_string_literal: true

require 'test_helper'

class DashboardHelperTest < ActionView::TestCase
  include DashboardHelper

  setup do
    @user = users(:user_two)
    @fiction = fictions(:one)
  end

  test 'crud_permissions? should return true for owned fiction' do
    @user.fictions << @fiction
    assert crud_permissions?(@fiction, @user)
  end

  test 'crud_permissions? should return true for owned chapter' do
    @admin = users(:user_one)
    chapter = chapters(:one)
    assert crud_permissions?(chapter, @admin)
  end

  test 'crud_permissions? should return false for non-owned fiction' do
    refute crud_permissions?(Fiction.new, @user)
  end

  test 'crud_permissions? should return false for chapter not within owned fiction' do
    refute crud_permissions?(Chapter.new, @user)
  end

  test 'crud_permissions? should return true for admin user' do
    @admin = users(:user_one)
    assert crud_permissions?(Fiction.new, @admin)
    assert crud_permissions?(Chapter.new, @admin)
  end
end
