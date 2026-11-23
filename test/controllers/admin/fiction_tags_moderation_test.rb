# frozen_string_literal: true

require 'test_helper'

module Admin
  class FictionTagsModerationTest < ActionDispatch::IntegrationTest
    include Devise::Test::IntegrationHelpers

    setup do
      sign_in users(:user_one)
      @tag = fiction_tags(:rebirth)
    end

    test 'rename keeps the slug stable' do
      patch admin_fiction_tag_url(@tag), params: { fiction_tag: { name: 'Реінкарнація' } }

      assert_redirected_to admin_fiction_tags_url
      assert_equal %w[Реінкарнація pererodzhennia], [@tag.reload.name, @tag.slug]
    end

    test 'rename to an existing name is refused with the message' do
      patch admin_fiction_tag_url(@tag), params: { fiction_tag: { name: 'ЛітРПГ' } }

      assert_equal 'Переродження', @tag.reload.name
      assert_predicate flash[:alert], :present?
    end

    test 'hide and show flip the status' do
      patch admin_fiction_tag_url(@tag), params: { fiction_tag: { status: 'hidden' } }

      assert_predicate @tag.reload, :hidden?

      patch admin_fiction_tag_url(@tag), params: { fiction_tag: { status: 'active' } }

      assert_predicate @tag.reload, :active?
    end

    test 'an unknown status is rejected' do
      patch admin_fiction_tag_url(@tag), params: { fiction_tag: { status: 'bogus' } }

      assert_predicate @tag.reload, :active?
      assert_predicate flash[:alert], :present?
    end

    test 'explicit toggles' do
      patch admin_fiction_tag_url(@tag), params: { fiction_tag: { explicit: true } }

      assert_predicate @tag.reload, :explicit?
    end

    test 'destroy removes the tag and its links and reports the count' do
      fictions(:one).fiction_tags << @tag

      assert_difference ['FictionTag.count', 'FictionTagLink.count'], -1 do
        delete admin_fiction_tag_url(@tag)
      end

      assert_includes flash[:notice], '1 творі'
    end

    test 'a non-admin cannot change a tag' do
      sign_in users(:user_two)

      patch admin_fiction_tag_url(@tag), params: { fiction_tag: { status: 'hidden' } }

      assert_predicate @tag.reload, :active?
    end
  end
end
