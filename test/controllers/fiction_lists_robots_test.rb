# frozen_string_literal: true

require 'test_helper'

# Every catalogue view with a query string is one catalogue page: noindex for search, canonical to the bare catalogue.
class FictionListsRobotsTest < ActionDispatch::IntegrationTest
  test 'the plain catalogue stays indexable and points to itself' do
    get alphabetical_fictions_url

    assert_select 'meta[name=robots][content=?]', 'max-image-preview:large'
    assert_select 'link[rel=canonical][href$=?]', alphabetical_fictions_path
  end

  test 'a sort variant is noindex and canonicalises to the bare catalogue' do
    get alphabetical_fictions_url, params: { sort: 'popular_desc' }

    assert_select 'meta[name=robots][content=?]', 'noindex, follow'
    assert_select 'link[rel=canonical][href$=?]', alphabetical_fictions_path
  end

  test 'a paginated variant is noindex and canonicalises to the bare catalogue' do
    get alphabetical_fictions_url, params: { page: 1 }

    assert_select 'meta[name=robots][content=?]', 'noindex, follow'
    assert_select 'link[rel=canonical][href$=?]', alphabetical_fictions_path
  end

  test 'a genre variant is noindex' do
    get alphabetical_fictions_url, params: { genre: genres(:bl).id }

    assert_select 'meta[name=robots][content=?]', 'noindex, follow'
  end
end
