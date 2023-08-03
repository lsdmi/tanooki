# frozen_string_literal: true

require 'test_helper'

class DashboardHelperTest < ActionView::TestCase
  include DashboardHelper

  setup do
    @user = users(:user_two)
    @fiction = fictions(:one)
  end
end
