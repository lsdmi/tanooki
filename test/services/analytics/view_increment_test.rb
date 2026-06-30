# frozen_string_literal: true

require 'test_helper'

module Analytics
  class ViewIncrementTest < ActiveSupport::TestCase
    setup do
      @fiction = fictions(:one)
      @session = {}
    end

    test 'remembers session and increments views via background job' do
      @fiction.update!(views: 0)

      ViewIncrement.new(@fiction, @session).call

      assert_equal [@fiction.slug], @session[:viewed]
      assert_equal 0, @fiction.reload.views

      ViewIncrementJob.perform_now('Fiction', @fiction.id)

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
