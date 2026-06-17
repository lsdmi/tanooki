# frozen_string_literal: true

require 'test_helper'

module Scanlators
  class ShowPresenterTest < ActiveSupport::TestCase
    setup do
      @scanlator = scanlators(:one)
      @original_cache = Rails.cache
      Rails.cache = ActiveSupport::Cache::MemoryStore.new
    end

    teardown do
      Rails.cache = @original_cache
    end

    test 'exposes cached stats values' do
      presenter = ShowPresenter.new(@scanlator)

      assert_equal 2, presenter.chapters_count
      assert_in_delta 4.5, presenter.average_rating
      assert_equal 2, presenter.total_rating_count
    end

    test 'reads stats from cache after the first load' do
      ShowPresenter.new(@scanlator).chapters_count

      Stats.stub(:compute, ->(*) { raise 'should not recompute' }) do
        assert_equal 2, ShowPresenter.new(@scanlator).chapters_count
      end
    end

    test 'invalidates cached stats for a scanlator' do
      presenter = ShowPresenter.new(@scanlator)
      presenter.chapters_count

      ShowPresenter.invalidate(@scanlator.id)
      @scanlator.chapters.first.update!(views: 25)

      assert_equal 25, ShowPresenter.new(@scanlator).total_views
    end
  end
end
