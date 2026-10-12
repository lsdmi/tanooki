# frozen_string_literal: true

require 'test_helper'

module Fictions
  class ChapterTeamFilterTest < ActionDispatch::IntegrationTest
    include Devise::Test::IntegrationHelpers

    setup do
      @fiction = fictions(:one)
      @other = scanlators(:two)
      FictionScanlator.create!(fiction: @fiction, scanlator: @other)
      @theirs = Chapter.create!(
        fiction: @fiction, user: users(:user_two), title: 'Other', number: 3, content: 'x' * 500,
        scanlator_ids: [@other.id]
      )
      ChapterScanlator.create!(chapter: @theirs, scanlator: @other)
      sign_in users(:user_one)
    end

    test 'a fiction with two teams starts on every translation, larger team first' do
      get fiction_url(@fiction)

      assert_select '[aria-label=Переклад] button[aria-pressed=true]', text: 'Усі'
      assert_equal %w[Усі One Two], team_labels
    end

    test 'picking a team keeps its chapters and the next visit remembers it' do
      post chapter_team_fiction_url(@fiction, order: :desc, team: @other.id), as: :turbo_stream
      get fiction_url(@fiction)

      assert_equal ["chapter_list_chapter_#{@theirs.id}"], row_ids
      assert_select 'button[aria-pressed=true]', text: 'Two'
    end

    test 'a guest remembers the team too' do
      sign_out users(:user_one)
      post chapter_team_fiction_url(@fiction, order: :desc, team: @other.id), as: :turbo_stream
      get fiction_url(@fiction)

      assert_select '[aria-label=Переклад] button[aria-pressed=true]', text: 'Two'
      assert_select '[data-chapter-group-pager-total-value=?]', '1'
    end

    test 'all clears the remembered team' do
      post chapter_team_fiction_url(@fiction, order: :desc, team: @other.id), as: :turbo_stream
      post chapter_team_fiction_url(@fiction, order: :desc), as: :turbo_stream
      get fiction_url(@fiction)

      assert_select '[aria-label=Переклад] button[aria-pressed=true]', text: 'Усі'
      assert_equal 3, row_ids.size
    end

    test 'a group page follows the team' do
      get chapter_section_fiction_path(@fiction, section: 'r-1-100', order: 'desc', team: @other.id)

      assert_equal ["chapter_list_chapter_#{@theirs.id}"], row_ids
    end

    test 'a jump into the other translation says the chapter is filtered' do
      get chapter_jump_fiction_url(@fiction, order: :desc, team: @other.id, number: '1')

      assert_equal 'Розділ 1 приховано фільтром', response.parsed_body['error']
    end

    private

    def row_ids = css_select('li[id^=chapter_list_chapter_]').pluck('id')

    def team_labels = css_select('[aria-label=Переклад] button').map { |button| button.text.squish }
  end
end
