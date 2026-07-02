# frozen_string_literal: true

require 'test_helper'

class HomeControllerTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  def setup
    @controller = HomeController.new
  end

  test 'should get index' do
    Search::TagCounts.stub(:call, {}) do
      get root_url
    end

    assert_response :success
    assert_equal({}, assigns(:video_tag_counts))
  end

  test 'hero shows guest acquisition copy for signed out users' do
    visit_guest_hero

    assert_select 'h1', text: /Найбільше джерело/
    assert_select 'h1 span', text: 'ранобе в Україні'
    assert_select 'p', text: /Сотні історій рідним словом.*єство життя/m
  end

  test 'hero guest calls to action' do
    visit_guest_hero

    assert_select "a[href='#{fictions_path}']", text: 'До оповідей'
    assert_select "a[href='#{new_user_session_path}']", text: 'Увійти'
    assert_select "a[href='#{library_path}']", count: 0
  end

  test 'hero shows personalized retention copy for signed in users' do
    visit_signed_in_hero

    assert_select 'h1', text: /Ласкаво просимо/
    assert_select 'h1 span', text: 'Бібліярні'
    assert_select 'p', text: /Скарбниця огорнулася новими оповідями.*бодай цей вечір стане сповненим дивом/m
  end

  test 'hero signed-in calls to action' do
    visit_signed_in_hero

    assert_select "a[href='#{fictions_path}']", text: 'До оповідей'
    assert_select "a[href='#{library_path}']", text: 'Збережені'
    assert_select "a[href='#{register_path}']", count: 0
  end

  private

  def visit_guest_hero
    Search::TagCounts.stub(:call, {}) { get root_url }
  end

  def visit_signed_in_hero
    sign_in users(:user_one)
    Search::TagCounts.stub(:call, {}) { get root_url }
  end
end
