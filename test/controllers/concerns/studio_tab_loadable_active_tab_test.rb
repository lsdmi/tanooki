# frozen_string_literal: true

require 'test_helper'
require_relative 'studio_tab_loadable_test_support'

class StudioTabLoadableActiveTabTest < ActiveSupport::TestCase
  setup do
    @user = users(:user_one)
    @harness = StudioTabLoadableHarness.new(@user)
  end

  test 'set_active_tab uses params tab when present' do
    @harness.params = ActionController::Parameters.new(tab: 'teams')
    @harness.session[:studio_tab] = 'profile'
    @harness.send(:set_active_tab)

    assert_equal 'teams', @harness.instance_variable_get(:@active_tab)
    assert_equal 'teams', @harness.session[:studio_tab]
  end

  test 'set_active_tab falls back to session when params tab blank' do
    @harness.params = ActionController::Parameters.new({})
    @harness.session[:studio_tab] = 'writings'
    @harness.send(:set_active_tab)

    assert_equal 'writings', @harness.instance_variable_get(:@active_tab)
    assert_equal 'writings', @harness.session[:studio_tab]
  end

  test 'set_active_tab uses default_tab when params and session blank' do
    @harness.params = ActionController::Parameters.new({})
    @harness.session = {}
    @harness.send(:set_active_tab)

    assert_equal 'blogs', @harness.instance_variable_get(:@active_tab)
    assert_equal 'blogs', @harness.session[:studio_tab]
  end

  test 'set_active_tab normalizes unknown tab id to blogs' do
    @harness.params = ActionController::Parameters.new(tab: 'not-a-real-tab')
    @harness.send(:set_active_tab)

    assert_equal 'blogs', @harness.instance_variable_get(:@active_tab)
  end
end
