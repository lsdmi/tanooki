# frozen_string_literal: true

require 'test_helper'

module Contests
  class HubPresenterTest < ActiveSupport::TestCase
    setup do
      @presenter = HubPresenter.new
    end

    test 'features the active contest over an announced one' do
      assert_equal contests(:submissions), @presenter.featured
      assert_equal :active, @presenter.hub_state
    end

    test 'features judging contest as active' do
      contests(:submissions).update!(published_at: nil)

      assert_equal contests(:judging), HubPresenter.new.featured
      assert_equal :active, HubPresenter.new.hub_state
    end

    test 'falls back to an announced contest' do
      cancel_contests!(:submissions, :judging)
      presenter = HubPresenter.new

      assert_equal contests(:announced), presenter.featured
      assert_equal :announced, presenter.hub_state
    end

    test 'is idle without active or announced contests' do
      cancel_contests!(:announced, :submissions, :judging)
      presenter = HubPresenter.new

      assert_nil presenter.featured
      assert_equal :idle, presenter.hub_state
    end

    test 'archive lists results and cancelled contests, newest first, without drafts' do
      archive = @presenter.archive.to_a

      assert_equal [contests(:cancelled), contests(:results)], archive
      assert_not_includes archive, contests(:draft)
    end

    test 'hall of fame lists place awards of published results' do
      awards = @presenter.hall_of_fame.to_a

      assert_equal [contest_awards(:legacy_first)], awards
    end

    test 'hall of fame can exclude a contest' do
      assert_empty @presenter.hall_of_fame(except: contests(:results))
    end

    private

    def cancel_contests!(*names)
      names.each { |name| contests(name).update!(cancelled_at: Time.current) }
    end
  end
end
