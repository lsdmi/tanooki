# frozen_string_literal: true

require 'test_helper'

module Fictions
  class ContinueTranslationComponentTest < ViewComponentTestCase
    setup do
      @fiction = fictions(:one)
      @new_chapter = "/chapters/new?fiction=#{@fiction.slug}"
    end

    test 'a licensed fiction offers no continuation' do
      @fiction.licensed_at = 1.day.ago

      render_continue(users(:user_two), :notice)

      assert_no_selector 'a'
    end

    test 'a reader from another team goes straight to the new chapter form' do
      render_continue(users(:user_two), :notice)

      assert_selector "a[href='#{@new_chapter}']", text: 'Продовжити переклад'
    end

    test 'a reader without a team is sent to create one, then back to the chapter form' do
      user = users(:user_two)
      user.scanlator_users.destroy_all

      render_continue(user.reload, :chapters)

      assert_selector "a[href='/scanlators/new?return_to=#{CGI.escape(@new_chapter)}']", text: 'Додати розділ'
    end

    test 'a guest is asked to log in and lands on the chapter form' do
      render_continue(nil, :chapters)

      assert_selector 'p', text: /Перекладаєте цей твір\?\s+Увійдіть, щоб додати розділ/
      assert_selector "a[href='/login?return_to=#{CGI.escape(@new_chapter)}']"
    end

    test 'the fiction team and admins without a team go straight to the chapter form' do
      admin = users(:user_one)
      render_continue(admin, :notice)

      assert_selector "a[href='#{@new_chapter}']", text: 'Продовжити переклад'

      admin.scanlator_users.destroy_all
      render_continue(admin.reload, :chapters)

      assert_selector "a[href='#{@new_chapter}']", text: 'Додати розділ'
    end

    test 'finished translations get nothing' do
      @fiction.completed_at = Time.current
      render_continue(users(:user_two), :chapters)

      assert_no_selector 'a'
    end

    private

    def render_continue(user, placement)
      render_inline(ContinueTranslationComponent.new(fiction: @fiction, user:, placement:))
    end
  end
end
