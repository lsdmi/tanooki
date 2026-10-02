# frozen_string_literal: true

require 'test_helper'

module Analytics
  class ViewIncrementTest < ActiveSupport::TestCase
    setup do
      @fiction = fictions(:one)
      @session = {}
      ViewCounter.default.clear
    end

    test 'remembers session and counts the view for the next write' do
      @fiction.update!(views: 0)

      ViewIncrementJob.stub(:perform_later, ->(*) { flunk 'enqueued a job per view' }) do
        ViewIncrement.new(@fiction, @session).call
      end

      assert_equal [@fiction.slug], @session[:viewed]
      assert_equal 0, @fiction.reload.views

      ViewCounter.default.flush

      assert_equal 1, @fiction.reload.views
    end

    test 'skips when already viewed in session' do
      @session[:viewed] = [@fiction.slug]
      @fiction.update!(views: 5)

      ViewIncrement.new(@fiction, @session).call

      assert_equal 5, @fiction.reload.views
    end
  end
end
