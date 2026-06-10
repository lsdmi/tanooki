# frozen_string_literal: true

require 'test_helper'

module Comments
  class PresentationTest < ActiveSupport::TestCase
    include Rails.application.routes.url_helpers

    test 'empty_state_for returns chapter copy' do
      assert_equal 'Наразі відгуки до цього розділу відсутні!', Presentation.empty_state_for('chapters')
    end

    test 'empty_state_for returns fiction copy' do
      assert_equal 'Наразі відгуки до цього твору відсутні!', Presentation.empty_state_for('fictions')
    end

    test 'empty_state_for returns default copy for other controllers' do
      assert_equal 'Наразі відгуки до цього допису відсутні!', Presentation.empty_state_for('tales')
    end

    test 'comment_url returns chapter path' do
      comment = comments(:comment_chapter)

      assert_equal chapter_path(comment.commentable), Presentation.new.comment_url(comment)
    end

    test 'commentable_title includes fiction and chapter for chapters' do
      chapter = comments(:comment_chapter).commentable

      assert_equal "#{chapter.fiction_title} · #{chapter.display_title_no_volume}",
                   Presentation.new.commentable_title(chapter)
    end
  end
end
