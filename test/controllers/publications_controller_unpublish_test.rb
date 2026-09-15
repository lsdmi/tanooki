# frozen_string_literal: true

require 'test_helper'

class PublicationsControllerUnpublishTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  setup do
    sign_in users(:user_one)
    @publication = publications(:tale_approved_one)
  end

  test 'draft intent unpublishes a live publication' do
    patch publication_url(@publication), params: unpublish_params

    assert_predicate @publication.reload, :draft?
    assert_redirected_to edit_publication_path(@publication)
  end

  test 'unpublished publication is hidden from guests' do
    patch publication_url(@publication), params: unpublish_params
    sign_out :user
    get tale_url(@publication)

    assert_redirected_to tales_path
  end

  private

  def unpublish_params
    {
      intent: 'draft',
      publication: { title: @publication.title, description: @publication.description }
    }
  end
end
