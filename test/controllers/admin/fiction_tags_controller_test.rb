# frozen_string_literal: true

require 'test_helper'

module Admin
  class FictionTagsControllerTest < ActionDispatch::IntegrationTest
    include Devise::Test::IntegrationHelpers

    setup do
      sign_in users(:user_one)
    end

    test 'new tab lists only tags created in the last two weeks, newest first' do
      FictionTag.create!(name: 'Свіжий', created_at: 1.day.ago)

      get admin_fiction_tags_url

      assert_response :success
      assert_select '#admin_fiction_tags li', count: 1
      assert_select '#admin_fiction_tags li input[name="fiction_tag[name]"][value="Свіжий"]'
    end

    test 'all tab lists every tag with its works count' do
      fictions(:one).fiction_tags << fiction_tags(:rebirth)

      get admin_fiction_tags_url(filter: 'all')

      assert_select '#admin_fiction_tags li', count: FictionTag.count
      assert_select "li#fiction_tag_#{fiction_tags(:rebirth).id}", text: /1 твір/
    end

    test 'hidden tab lists hidden tags only' do
      get admin_fiction_tags_url(filter: 'hidden')

      assert_select '#admin_fiction_tags li', count: 1
      assert_select 'input[value="Юрі"]'
    end

    test 'search narrows the list by name' do
      get admin_fiction_tags_url(filter: 'all', q: 'літ')

      assert_select '#admin_fiction_tags li', count: 1
      assert_select 'input[value="ЛітРПГ"]'
    end

    test 'create adds an active tag and lands on the new tab' do
      assert_difference 'FictionTag.count', 1 do
        post admin_fiction_tags_url, params: { fiction_tag: { name: '  #Нова   ідея ' } }
      end

      assert_redirected_to admin_fiction_tags_url(filter: 'new')
      assert_predicate FictionTag.find_by!(name: 'Нова ідея'), :active?
    end

    test 'create rejects a duplicate and shows the message' do
      assert_no_difference 'FictionTag.count' do
        post admin_fiction_tags_url, params: { fiction_tag: { name: 'переродження' } }
      end

      assert_response :unprocessable_content
      assert_select 'p.text-status-danger-solid'
    end

    test 'a non-admin cannot reach the page' do
      sign_in users(:user_two)

      get admin_fiction_tags_url

      assert_redirected_to root_url
    end
  end
end
