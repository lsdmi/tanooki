# frozen_string_literal: true

require 'test_helper'

class FictionsControllerShareTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  setup do
    sign_in users(:user_one)
    @fiction = fictions(:one)
  end

  test 'hero actions include an icon share control with the fiction URL' do
    get fiction_url(@fiction)

    assert_select '#fiction-hero-actions [data-controller="share-link"][data-share-link-url-value=?]',
                  fiction_url(@fiction)
    assert_select '#fiction-hero-actions [data-action="share-link#share"][title=?]', 'Поділитися'
    assert_select '#fiction-hero-actions [data-share-link-target="label"].md\\:sr-only', text: 'Поділитися'
  end
end
