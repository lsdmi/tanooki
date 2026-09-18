# frozen_string_literal: true

require 'test_helper'

class FormFailureRenderTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  setup do
    sign_in users(:user_one)
  end

  test 'scanlator edit form disables turbo' do
    get edit_scanlator_path(scanlators(:one))

    assert_response :success
    assert_select 'form[data-turbo="false"]'
  end

  test 'failed scanlator update re-renders edit with slimselect' do
    patch scanlator_path(scanlators(:one)), params: {
      scanlator: { title: 'x', member_ids: [users(:user_one).id] }
    }

    assert_response :unprocessable_content
    assert_select 'form[data-turbo="false"]'
    assert_select 'select[data-controller="slim"]'
  end

  test 'failed scanlator update keeps slimselect stylesheet' do
    patch scanlator_path(scanlators(:one)), params: {
      scanlator: { title: 'x', member_ids: [users(:user_one).id] }
    }

    assert_select 'link[href*="slimselect"][data-turbo-track="reload"]'
  end

  test 'publication edit form disables turbo' do
    get edit_publication_path(publications(:tale_approved_one))

    assert_select 'form[data-turbo="false"]'
    assert_select 'select[data-controller="slim"]'
  end

  test 'failed publication publish re-renders with slimselect' do
    post publications_url, params: {
      intent: 'publish',
      publication: { type: 'Tale', title: 'Too short', description: 'short' }
    }

    assert_response :unprocessable_content
    assert_select 'form[data-turbo="false"]'
    assert_select 'select[data-controller="slim"]'
  end

  test 'failed chapter update re-renders with slimselect and flatpickr' do
    patch chapter_url(chapters(:one)), params: { chapter: { content: '', number: '', title: '' } }

    assert_response :unprocessable_content
    assert_select 'form[data-turbo="false"]'
    assert_select 'select[data-controller="slim"]'
  end

  test 'failed chapter update keeps composer stylesheets' do
    patch chapter_url(chapters(:one)), params: { chapter: { content: '', number: '', title: '' } }

    assert_select 'link[href*="slimselect"][data-turbo-track="reload"]'
    assert_select 'link[href*="flatpickr_overrides"][data-turbo-track="reload"]'
  end

  test 'failed fiction update re-renders with slimselect' do
    patch fiction_url(fictions(:one)), params: {
      fiction: {
        title: '',
        scanlator_ids: [scanlators(:one).id]
      }
    }

    assert_response :unprocessable_content
    assert_select 'form[data-turbo="false"]'
    assert_select 'select[data-controller="slim"]'
  end

  test 'failed bookshelf update re-renders with turbo disabled' do
    bookshelf = bookshelves(:one)

    patch bookshelf_url(bookshelf.sqid), params: {
      bookshelf: { title: '', description: 'Updated description', fiction_ids: [fictions(:one).id] }
    }

    assert_response :unprocessable_content
    assert_select 'form[data-turbo="false"]'
  end
end
