# frozen_string_literal: true

require 'test_helper'

module Fictions
  class ChapterRowMenuTest < ActionDispatch::IntegrationTest
    include Devise::Test::IntegrationHelpers

    setup do
      @user = users(:user_one)
      @fiction = fictions(:one)
      ReadingChapterRead.where(user: @user).delete_all
      reading_progresses(:one).update!(chapter: chapters(:two), status: :active, resume_at: Time.current)
      @third = Chapter.create!(fiction: @fiction, user: @user, title: 'Chapter 3', number: 3, content: 'x' * 500,
                               scanlator_ids: [scanlators(:one).id])
      sign_in @user
    end

    test 'rows offer the row menu with the range up to them' do
      get fiction_url(@fiction)

      assert_select "#{row(chapters(:two))}[data-read-through=?] button[data-row-menu-button]", '1–2'
      assert_select "#{row(chapters(:one))}:not([data-read-through]) button[data-row-menu-button]"
      assert_select '[data-chapter-row-menu-url-value=?] [data-chapter-row-menu-target=sheet]',
                    fiction_read_through_path(@fiction), count: 1
    end

    test 'the range is gone once every chapter before the row is read' do
      ReadingChapterRead.create!(user: @user, fiction: @fiction, chapter: chapters(:one), completed_at: Time.current,
                                 source: 'manual')
      get fiction_url(@fiction)

      assert_select "#{row(chapters(:two))}:not([data-read-through])"
      assert_select "#{row(@third)}[data-read-through=?]", '1–3'
    end

    test 'guests get no row menu' do
      sign_out @user
      get fiction_url(@fiction)

      assert_select '[data-row-menu-button], [data-controller~=chapter-row-menu]', count: 0
    end

    private

    def row(chapter) = "li#chapter_list_chapter_#{chapter.id}"
  end
end
