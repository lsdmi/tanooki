# frozen_string_literal: true

require 'test_helper'
require_relative '../../services/fictions/merge_fixture'

module Admin
  class FictionDuplicatesControllerTest < ActionDispatch::IntegrationTest
    include Devise::Test::IntegrationHelpers
    include Fictions::MergeFixture

    setup do
      @admin = users(:user_one)
      sign_in @admin
    end

    test 'an admin sees a candidate group and which page would survive' do
      keep = listed('dup-keep', 'Спільний твір')
      listed('dup-drop', 'Спільний твір')
      keep.assign_attributes(chapter_count: 4, last_chapter_at: Time.current)
      keep.save!(validate: false)

      get admin_fiction_duplicates_url

      assert_response :success
      assert_select 'h2', text: 'Спільний твір'
      assert_select 'li', text: /Залишиться ця сторінка/
    end

    test 'not a duplicate hides the pair' do
      left = listed('dup-left', 'Інший твір')
      right = listed('dup-right', 'Інший твір')

      post dismiss_admin_fiction_duplicates_url, params: { fiction_ids: [left.id, right.id] }
      follow_redirect!

      assert_equal [left.id, right.id].minmax, FictionDuplicateDismissal.pick(:fiction_id, :other_fiction_id)
      assert_select 'h2', text: 'Інший твір', count: 0
    end

    test 'merge moves the other page onto the one that survives' do
      target = listed('dup-target', 'Злитий твір')
      source = listed('dup-source', 'Злитий твір')
      target.assign_attributes(chapter_count: 3, last_chapter_at: Time.current)
      target.save!(validate: false)
      chapter = build_chapter(source, 'dup-source-ch', 1)

      post merge_admin_fiction_duplicates_url, params: { fiction_ids: [source.id, target.id] }

      assert_redirected_to admin_fiction_duplicates_path
      assert_equal target.id, chapter.reload.fiction_id
      assert_predicate source.reload, :deleted?
    end

    test 'ids that are not a current group are left alone' do
      post merge_admin_fiction_duplicates_url, params: { fiction_ids: [fictions(:one).id, fictions(:two).id] }

      assert_redirected_to admin_fiction_duplicates_path
      assert_equal 0, FictionDuplicateDismissal.count
      assert_not fictions(:one).reload.deleted?
    end

    test 'a reader is sent home' do
      sign_in users(:user_two)

      get admin_fiction_duplicates_url

      assert_redirected_to root_path
    end

    private

    def listed(slug, title)
      build_fiction(slug, title)
    end
  end
end
