# frozen_string_literal: true

require 'test_helper'

module Library
  class EntryComponentTest < ViewComponent::TestCase
    setup do
      @user = users(:user_one)
      @reading = reading_progresses(:one)
      ReadingChapterRead.where(user: @user).delete_all
    end

    test 'a reading not opened yet offers to start from the first chapter' do
      @reading.update!(status: :active, chapter: chapters(:one), resume_at: nil)
      render_entry

      assert_selector 'p', text: '2 розділи · ще не почали'
      assert_selector "a[href^='/chapters/#{chapters(:one).slug}']", text: 'Почати читати'
    end

    test 'a reading in progress names the next chapter and continues there' do
      @reading.update!(status: :active, chapter: chapters(:one), resume_at: Time.current)
      render_entry

      assert_selector 'p', text: '0 з 2 · далі розділ 1'
      assert_link 'Продовжити', href: "/chapters/#{chapters(:one).slug}?resume=1"
    end

    test 'the title link covers the row and the shelf menu sits beside it' do
      @reading.update!(status: :active)
      render_entry

      assert_selector "a.after\\:absolute[href='/fictions/#{@reading.fiction.slug}']", text: @reading.fiction.title
      assert_selector "#library-shelf-menu-#{@reading.id}[role=dialog]", visible: :all
    end

    private

    def render_entry
      render_inline(EntryComponent.new(reading: @reading, section: :active, viewer: @user))
    end
  end
end
