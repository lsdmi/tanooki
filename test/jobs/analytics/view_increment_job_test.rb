# frozen_string_literal: true

require 'test_helper'

module Analytics
  class ViewIncrementJobTest < ActiveJob::TestCase
    test 'increments views for every show-page model' do
      records = {
        'Bookshelf' => bookshelves(:one),
        'Chapter' => chapters(:one),
        'Fiction' => fictions(:one),
        'Publication' => publications(:tale_approved_one),
        'Tale' => publications(:tale_created_one),
        'YoutubeVideo' => youtube_videos(:one)
      }

      records.each do |class_name, record|
        before = record.views.to_i

        ViewIncrementJob.perform_now(class_name, record.id)

        assert_equal before + 1, record.reload.views, class_name
      end
    end

    test 'no-ops when record was deleted' do
      assert_nothing_raised do
        ViewIncrementJob.perform_now('Publication', -1)
      end
    end

    test 'does not increment a soft-deleted fiction' do
      fiction = fictions(:one)
      views = fiction.views
      fiction.destroy

      ViewIncrementJob.perform_now('Fiction', fiction.id)

      assert_equal views, Fiction.unscoped.find(fiction.id).views
    end

    test 'no-ops for an unknown class name' do
      assert_nothing_raised do
        ViewIncrementJob.perform_now('User', users(:user_one).id)
      end
    end
  end
end
