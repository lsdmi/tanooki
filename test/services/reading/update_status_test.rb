# frozen_string_literal: true

require 'test_helper'

module Reading
  class UpdateStatusTest < ActiveSupport::TestCase
    setup do
      @user = users(:user_one)
      @reading_progress = reading_progresses(:one)
      @reading_progress.update!(status: :active)
    end

    test 'updates to a whitelisted status' do
      result = UpdateStatus.new(@reading_progress, :finished, @user).call

      assert_predicate result, :success?
      assert_equal 'finished', @reading_progress.reload.status
    end

    test 'destroys reading progress when status is destroy' do
      assert_difference('ReadingProgress.count', -1) do
        result = UpdateStatus.new(@reading_progress, :destroy, @user).call

        assert_predicate result, :success?
      end
    end

    test 'rejects invalid status without changing record' do
      ProgressCacheInvalidation.stub(:new, ->(*) { raise 'cache should not be cleared' }) do
        result = UpdateStatus.new(@reading_progress, :invalid, @user).call

        assert_predicate result, :failure?
      end

      assert_equal 'active', @reading_progress.reload.status
    end

    test 'rejects blank status' do
      result = UpdateStatus.new(@reading_progress, '', @user).call

      assert_predicate result, :failure?
      assert_equal 'active', @reading_progress.reload.status
    end

    test 'normalize_status accepts string and symbol forms' do
      assert_equal 'finished', UpdateStatus.normalize_status('finished')
      assert_equal 'finished', UpdateStatus.normalize_status(:finished)
      assert_nil UpdateStatus.normalize_status('not_a_status')
    end

    test 'normalize_status defaults blank create param to active' do
      assert_equal 'active', UpdateStatus.normalize_status(nil, default: 'active')
    end
  end
end
