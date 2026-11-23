# frozen_string_literal: true

require 'test_helper'

module Admin
  class FictionTagMergesControllerTest < ActionDispatch::IntegrationTest
    include Devise::Test::IntegrationHelpers

    setup do
      sign_in users(:user_one)
      @source = fiction_tags(:rebirth)
      @target = fiction_tags(:litrpg)
    end

    test 'the form offers active tags other than the source' do
      get new_admin_fiction_tag_merge_url(@source)

      assert_select 'select#target_id option', text: /ЛітРПГ/
      assert_select 'select#target_id option', text: /Переродження|Юрі/, count: 0
    end

    test 'merge moves the works onto the target and deletes the source' do
      fictions(:one).fiction_tags << @source

      post admin_fiction_tag_merge_url(@source), params: { target_id: @target.id }

      assert_redirected_to admin_fiction_tags_url(filter: 'all')
      assert_not FictionTag.exists?(@source.id)
      assert_equal [@target], fictions(:one).fiction_tags.reload.to_a
    end

    test 'merge into a hidden tag is refused without changes' do
      post admin_fiction_tag_merge_url(@source), params: { target_id: fiction_tags(:yuri_hidden).id }

      assert_redirected_to new_admin_fiction_tag_merge_url(@source)
      assert FictionTag.exists?(@source.id)
    end

    test 'merge into itself is refused without changes' do
      post admin_fiction_tag_merge_url(@source), params: { target_id: @source.id }

      assert_redirected_to new_admin_fiction_tag_merge_url(@source)
      assert FictionTag.exists?(@source.id)
    end

    test 'a non-admin cannot merge' do
      sign_in users(:user_two)

      post admin_fiction_tag_merge_url(@source), params: { target_id: @target.id }

      assert FictionTag.exists?(@source.id)
    end
  end
end
