# frozen_string_literal: true

require 'test_helper'

class FictionsCoverPreviewTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  setup do
    sign_in users(:user_one)
    @fiction = fictions(:one)
  end

  test 'new fiction form includes cover preview controller' do
    get new_fiction_url

    assert_response :success
    assert_select '[data-controller="fiction-cover-preview"]'
    assert_select '#fictions_cover[data-fiction-cover-preview-target="input"]'
  end

  test 'new fiction form cover preview markup and accept types' do
    get new_fiction_url

    assert_select '[data-fiction-cover-preview-target="previewImage"].object-cover.object-center'
    assert_select '[data-fiction-cover-preview-target="warnings"]'
    assert_select '#fictions_cover[accept="image/webp,image/avif"]'
  end

  test 'edit fiction form wires cover preview stimulus controller' do
    get edit_fiction_url(@fiction)

    assert_response :success
    assert_select '[data-controller="fiction-cover-preview"]'
    assert_select '[data-fiction-cover-preview-target="panel"].hidden'
  end
end
