# frozen_string_literal: true

require 'test_helper'

class TurboFlashStreamTest < ActiveSupport::TestCase
  class Harness
    include TurboFlashStream

    def turbo_stream
      @turbo_stream ||= Turbo::Streams::TagBuilder.new(view_context)
    end

    def view_context
      @view_context ||= ActionController::Base.new.view_context
    end

    def destroy_success_streams(list_stream, message)
      turbo_stream_destroy_success(list_stream, message)
    end

    def cleared_flash_streams(*streams)
      turbo_stream_with_cleared_flash(*streams)
    end
  end

  setup do
    @harness = Harness.new
    @list_stream = @harness.turbo_stream.update('foo-list', html: 'bar')
  end

  test 'turbo_stream_with_cleared_flash prepends clear frames to multiple streams' do
    streams = @harness.cleared_flash_streams(@list_stream, @list_stream)

    assert_stream_bundle(streams, size: 4, targets: %w[application-notice application-alert foo-list])
  end

  test 'turbo_stream_destroy_success clears flashes refreshes list and sets notice' do
    streams = @harness.destroy_success_streams(@list_stream, 'Deleted.')

    assert_stream_bundle(
      streams,
      size: 5,
      targets: %w[application-notice application-alert foo-list],
      message: 'Deleted.'
    )
  end

  private

  def assert_stream_bundle(streams, size:, targets:, message: nil)
    rendered = streams.map(&:to_s).join

    assert_equal size, streams.size
    targets.each { |target| assert_includes rendered, "target=\"#{target}\"" }
    assert_includes rendered, message if message
  end
end
