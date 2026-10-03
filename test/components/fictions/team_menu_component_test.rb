# frozen_string_literal: true

require 'test_helper'

module Fictions
  class TeamMenuComponentTest < ViewComponentTestCase
    setup do
      @fiction = fictions(:one)
    end

    test 'a member of the fiction team gets add chapter, chapter management and edit links' do
      member = users(:user_one_one_zero)
      ScanlatorUser.create!(user: member, scanlator: scanlators(:one))

      render_inline(TeamMenuComponent.new(fiction: @fiction, user: member))

      assert_selector "a[href='/chapters/new?fiction=#{@fiction.slug}']", text: 'Додати розділ', visible: :all
      assert_selector "a[href='/readings/#{@fiction.slug}']", text: 'Керувати розділами', visible: :all
      assert_selector "a[href='/fictions/#{@fiction.slug}/edit']", text: 'Редагувати твір', visible: :all
    end

    test 'an admin outside the team gets the menu too' do
      render_inline(TeamMenuComponent.new(fiction: fictions(:two), user: users(:user_one)))

      assert_selector 'button', text: 'Керування'
    end

    test 'a member of another team gets nothing' do
      render_inline(TeamMenuComponent.new(fiction: @fiction, user: users(:user_two)))

      assert_no_selector '#fiction-team-menu', visible: :all
    end

    test 'a guest gets nothing' do
      render_inline(TeamMenuComponent.new(fiction: @fiction, user: nil))

      assert_no_selector '#fiction-team-menu', visible: :all
    end
  end
end
