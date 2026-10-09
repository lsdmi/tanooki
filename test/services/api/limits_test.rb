# frozen_string_literal: true

require 'test_helper'

module Api
  class LimitsTest < ActiveSupport::TestCase
    setup do
      @user = users(:user_two)
      @limits = Limits.new(@user)
    end

    teardown do
      ENV.delete('API_WRITES_ENABLED')
      Limits.allow_writes!
      %i[unpublish published_edit_hour published_edit_day].each do |kind|
        Rails.cache.delete(Limits.counter_key(kind, @user, Date.current))
        Rails.cache.delete(Limits.counter_key(kind, @user, Time.current.strftime('%Y%m%d%H')))
      end
    end

    test 'the sixth unpublish in a day is refused' do
      5.times { @limits.record_unpublish! }
      error = assert_raises(Error) { @limits.record_unpublish! }

      assert_equal 'unpublish_cap', error.code
      assert_equal :too_many_requests, error.status
    end

    test 'the thirty first published edit in an hour is refused' do
      Limits::PUBLISHED_EDITS_PER_HOUR.times { @limits.record_published_edit! }
      error = assert_raises(Error) { @limits.record_published_edit! }

      assert_equal 'published_edit_cap', error.code
    end

    test 'the two hundred first published edit in a day is refused' do
      Rails.cache.increment(
        Limits.counter_key(:published_edit_day, @user, Date.current),
        Limits::PUBLISHED_EDITS_PER_DAY,
        expires_in: 1.hour
      )
      error = assert_raises(Error) { @limits.record_published_edit! }

      assert_equal 'published_edit_cap', error.code
    end

    test 'a published rewrite may keep seventy percent of the text' do
      text = 'а' * 1000

      assert_nothing_raised { Limits.refuse_published_rewrite!(text, 'а' * 700) }
    end

    test 'a published rewrite that drops more than thirty percent is refused' do
      error = assert_raises(Error) { Limits.refuse_published_rewrite!('а' * 1000, 'а' * 699) }

      assert_equal 'rewrite_too_small', error.code
      assert_equal :unprocessable_entity, error.status
    end

    test 'markup is ignored when measuring how much text was removed' do
      before_html = "<p>#{'а' * 1000}</p>"
      error = assert_raises(Error) { Limits.refuse_published_rewrite!(before_html, "<p>#{'а' * 600}</p>") }

      assert_equal 'rewrite_too_small', error.code
    end

    test 'a published rewrite under 500 characters is refused' do
      error = assert_raises(Error) { Limits.refuse_published_rewrite!('а' * 1000, 'а' * 499) }

      assert_equal 'rewrite_too_short', error.code
    end

    test 'paragraph edits are limited to fifty blocks' do
      assert_nothing_raised { Limits.refuse_too_many_blocks!(50) }

      error = assert_raises(Error) { Limits.refuse_too_many_blocks!(51) }

      assert_equal 'too_many_blocks', error.code
    end

    test 'API_WRITES_ENABLED false refuses a write' do
      ENV['API_WRITES_ENABLED'] = 'false'
      error = assert_raises(Error) { @limits.record_unpublish! }

      assert_equal 'writes_disabled', error.code
      assert_not Limits.writes_enabled?
    end

    test 'the cache switch refuses a write without a deploy' do
      Limits.stop_writes!
      error = assert_raises(Error) { @limits.record_unpublish! }

      assert_equal 'writes_disabled', error.code
    end
  end
end
