# frozen_string_literal: true

require 'test_helper'

class AdvertisementsHelperTest < ActionView::TestCase
  include Devise::Test::IntegrationHelpers

  setup do
    @advertisement_description = action_text_rich_texts(:rich_text_one)
    @advertisement_body = "\n  #{@advertisement_description.body.to_plain_text}\n\n"
  end

  test 'should get formatted_description' do
    assert_equal formatted_description(@advertisement_description), @advertisement_body
  end
end
