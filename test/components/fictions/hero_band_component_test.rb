# frozen_string_literal: true

require 'test_helper'

module Fictions
  class HeroBandComponentTest < ViewComponentTestCase
    setup do
      @fiction = fictions(:one)
      @user = users(:user_one)
    end

    test 'title, original titles and the status pill' do
      @fiction.update!(english_title: 'English Title', alternative_title: 'Original',
                       completed_at: nil, chapter_count: 2, last_chapter_at: 1.day.ago)
      render_hero

      assert_selector 'h1#fiction-title', text: @fiction.title
      assert_text 'English Title · Original'
      assert_selector 'span', text: 'Видається'
    end

    test 'credits link the author and every translation team' do
      @fiction.update!(author: 'Автор Твору')
      render_hero

      assert_selector 'a', text: 'Автор Твору'
      @fiction.scanlators.each { |scanlator| assert_selector "a[href='/scanlators/#{scanlator.slug}']" }
    end

    test 'age tag only for age-labelled works' do
      @fiction.update!(content_rating: :eighteen)
      render_hero

      assert_selector 'span.bg-rose-600', text: '18+'

      @fiction.update!(content_rating: :everyone)
      render_hero

      assert_no_selector 'span.bg-rose-600'
    end

    test 'stats line pluralizes and compacts large view counts' do
      @fiction.update!(views: 5100, chapter_count: 106)
      render_hero

      assert_selector 'li', text: '5.1т переглядів'
      assert_selector 'li', text: '106 розділів'
    end

    test 'stats line without ratings and small view counts' do
      @fiction.fiction_ratings.delete_all
      @fiction.update!(views: 22, chapter_count: 1)
      render_hero

      assert_selector 'li', text: /\A\s*—\s*\z/
      assert_selector 'li', text: '22 перегляди'
      assert_selector 'li', text: '1 розділ'
    end

    test 'backdrop is the cover even when the fiction has a banner' do
      @fiction.cover.attach(valid_cover_upload)
      @fiction.banner.attach(valid_cover_upload)
      render_hero

      assert_no_selector 'source[media]', visible: :all
      backdrop_src, cover_src = page.all('picture img', visible: :all).pluck('src')

      assert_equal cover_src, backdrop_src
    end

    test 'notice slot renders above the cover' do
      render_inline(component(user: nil)) { |hero| hero.with_notice { 'Статус перекладу' } }

      assert_text 'Статус перекладу'
    end

    test 'logged out offers sign-in instead of the shelf picker' do
      render_hero(user: nil)

      assert_selector '[data-controller="guest-continue"]'
      assert_selector 'a', text: 'Додати до читальні'
      assert_no_selector '[data-controller~="bottom-sheet"]'
    end

    test 'logged in gets the shelf picker' do
      render_hero

      assert_selector '[data-controller~="bottom-sheet"]'
      assert_no_selector '[data-controller="guest-continue"]'
    end

    private

    def component(user: @user)
      HeroBandComponent.new(fiction: @fiction, presenter: FictionShowPresenter.new(@fiction, user), user:)
    end

    def render_hero(user: @user)
      render_inline(component(user:))
    end
  end
end
