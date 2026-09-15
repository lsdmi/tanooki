# frozen_string_literal: true

require 'test_helper'

class TalesControllerDraftTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  setup do
    @publication = publications(:tale_approved_one)
    @publication.update!(status: :draft)
    Rails.cache.delete(Publications::PublicCache::HIGHLIGHTS_KEY)
    Rails.cache.delete(Publications::PublicCache::EXCLUDING_HIGHLIGHTS_KEY)
    Rails.cache.delete(Publications::PublicCache.show_key(@publication.slug))
    Rails.cache.delete(Publications::PublicCache.show_key(@publication.id))
  end

  test 'guest is redirected away from draft tale show' do
    get tale_url(@publication)

    assert_redirected_to tales_path
  end

  test 'guest cannot guess-edit a draft publication' do
    get edit_publication_path(@publication)

    assert_redirected_to new_user_session_path
  end

  test 'outsider cannot guess-edit a draft publication' do
    sign_in users(:user_two)
    get edit_publication_path(@publication)

    assert_redirected_to root_path
  end

  test 'guest cannot patch a draft publication' do
    patch publication_url(@publication), params: { publication: { title: 'Hijacked title here' } }

    assert_redirected_to new_user_session_path
    assert_not_equal 'Hijacked title here', @publication.reload.title
  end

  test 'non owner is redirected away from draft tale show' do
    sign_in users(:user_two)
    get tale_url(@publication)

    assert_redirected_to tales_path
  end

  test 'author is sent from draft show to edit' do
    sign_in users(:user_one)
    get tale_url(@publication)

    assert_redirected_to edit_publication_path(@publication)
  end

  test 'guest show does not cache a draft' do
    get tale_url(@publication)

    assert_nil Rails.cache.read(Publications::PublicCache.show_key(@publication.slug))
  end

  test 'tales index omits drafts' do
    Search::TagCounts.stub(:call, {}) { get tales_url }

    assert_response :success
    assert_select 'a[href=?]', tale_path(@publication), count: 0
  end

  test 'tales index omits drafts even when cached highlight ids include them' do
    Rails.cache.write(Publications::PublicCache::HIGHLIGHTS_KEY, [@publication.id])
    Search::TagCounts.stub(:call, {}) { get tales_url }

    assert_select 'a[href=?]', tale_path(@publication), count: 0
  end
end
