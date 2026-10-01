# frozen_string_literal: true

require 'test_helper'

module Fictions
  class TeamToolbarComponentTest < ViewComponentTestCase
    setup do
      @fiction = fictions(:one)
    end

    test 'a member of the fiction team gets add chapter, chapter management and edit links' do
      member = users(:user_one_one_zero)
      ScanlatorUser.create!(user: member, scanlator: scanlators(:one))

      render_inline(TeamToolbarComponent.new(fiction: @fiction, user: member))

      assert_selector "a[href='/chapters/new?fiction=#{@fiction.slug}']", text: 'Додати розділ'
      assert_selector "a[href='/readings/#{@fiction.slug}']", text: 'Керувати розділами'
      assert_selector "a[href='/fictions/#{@fiction.slug}/edit']", text: 'Редагувати твір'
    end

    test 'an admin outside the team gets the links too' do
      render_inline(TeamToolbarComponent.new(fiction: fictions(:two), user: users(:user_one)))

      assert_selector 'h2', text: 'Керування перекладом'
    end

    test 'a member of another team gets nothing' do
      render_inline(TeamToolbarComponent.new(fiction: @fiction, user: users(:user_two)))

      assert_no_selector 'section'
    end

    test 'a guest gets nothing' do
      render_inline(TeamToolbarComponent.new(fiction: @fiction, user: nil))

      assert_no_selector 'section'
    end
  end
end
