# frozen_string_literal: true

require 'test_helper'

module Library
  class EntryPreloadTest < ActiveSupport::TestCase
    setup do
      @user = users(:user_two)
      @readings = [reading_progresses(:one), reading_progresses(:two)]
      @readings.each { |reading| reading.update!(user: @user) }
      ReadingChapterRead.create!(user: @user, fiction: fictions(:one), chapter: chapters(:one),
                                 completed_at: Time.current, source: 'manual')
    end

    teardown { RequestMemo.reset }

    test 'stores the chapter lists and read keys the rows would load one by one' do
      expected = @readings.map { |reading| row_data(reading.fiction) }
      RequestMemo.reset

      EntryPreload.call(@readings, viewer: @user)

      actual = nil
      assert_no_queries { actual = @readings.map { row_data(it.fiction) } }

      assert_equal expected, actual
    end

    test 'a licensed work keeps loading its own list' do
      fictions(:two).update!(licensed_at: 1.day.ago, license_publisher: 'Видавництво')

      EntryPreload.call(@readings, viewer: @user)

      assert_nil RequestMemo.peek(:listed_chapters, fictions(:two).id, @user.id, true)
      assert_not_nil RequestMemo.peek(:listed_chapters, fictions(:one).id, @user.id, true)
    end

    private

    def row_data(fiction)
      [ChapterCatalog.listed_chapters(fiction, viewer: @user).map(&:id),
       Reading::ReadKeys.call(user: @user, fiction:, progress: nil)]
    end
  end
end
