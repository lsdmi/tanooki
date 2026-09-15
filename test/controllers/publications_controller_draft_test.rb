# frozen_string_literal: true

require 'test_helper'

class PublicationsControllerDraftTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  setup do
    sign_in users(:user_one)
  end

  test 'save draft with short description and no cover succeeds' do
    assert_difference('Publication.count', 1) do
      post publications_url, params: draft_post_params(description: 'short', title: '')
    end

    publication = Publication.order(:id).last

    assert_predicate publication, :draft?
    assert_redirected_to edit_publication_path(publication)
  end

  test 'publish with short description is unprocessable' do
    assert_no_difference('Publication.count') do
      post publications_url, params: publish_post_params(cover: nil, description: 'short', title: 'Too short')
    end

    assert_response :unprocessable_content
  end

  test 'crafted status published on a draft post does not publish' do
    post publications_url, params: draft_post_params(
      description: 'short',
      title: 'Crafted status',
      status: 'published'
    )

    assert_predicate Publication.order(:id).last, :draft?
  end

  test 'missing intent still publishes' do
    post publications_url, params: { publication: publish_attrs }

    publication = Publication.order(:id).last

    assert_predicate publication, :published?
    assert_redirected_to root_path
  end

  test 'studio blogs draft title links to edit and published title stays on tale' do
    post publications_url, params: draft_post_params(description: 'short', title: 'Studio draft blog')
    draft = Publication.order(:id).last

    get studio_index_path(tab: 'blogs')

    assert_select 'a[href=?]', edit_publication_path(draft)
    assert_select 'a[href=?]', tale_path(draft), count: 0
    assert_select 'a[href=?]', tale_path(publications(:tale_approved_one))
  end

  private

  def draft_post_params(**overrides)
    { intent: 'draft', publication: publish_attrs(**overrides) }
  end

  def publish_post_params(**overrides)
    { intent: 'publish', publication: publish_attrs(**overrides) }
  end

  def publish_attrs(**overrides)
    {
      type: 'Tale',
      title: 'A valid publication title',
      description: 'x' * 500,
      cover: Rack::Test::UploadedFile.new(
        Rails.root.join('app/assets/images/logo-default.svg'),
        'image/svg'
      )
    }.merge(overrides)
  end
end
