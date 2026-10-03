# frozen_string_literal: true

require 'test_helper'

module Fictions
  class TeamNoticesComponentTest < ViewComponentTestCase
    setup do
      @fiction = fictions(:one)
    end

    test 'shows every team notice with the team name' do
      FictionScanlator.find_or_create_by!(fiction: @fiction, scanlator: scanlators(:two))
      fiction = @fiction.reload
      notices = { scanlators(:one).id => 'Нові розділи щосуботи', scanlators(:two).id => 'Шукаємо редактора: https://t.me/example' }
      fiction.scanlators.each { |team| team.notice = notices[team.id] }

      render_inline(TeamNoticesComponent.new(fiction:))

      assert_selector 'li', count: 2
      assert_selector 'li', text: /Нові розділи щосуботи.*One.*Команда/m
      assert_selector 'li a[href="https://t.me/example"]'
    end

    test 'renders nothing when no team has a notice' do
      @fiction.scanlators.each { |team| team.notice = nil }

      render_inline(TeamNoticesComponent.new(fiction: @fiction))

      assert_no_selector 'section'
    end
  end
end
