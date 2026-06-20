# frozen_string_literal: true

require 'test_helper'

class TurboFlashStreamResponseTest < ActiveSupport::TestCase
  class Harness < ApplicationController
    public :append_session_flash_to_turbo_stream
  end

  setup do
    @controller = Harness.new
    @controller.request = ActionDispatch::TestRequest.create
    @controller.response = ActionDispatch::TestResponse.new
    @controller.response.content_type = Mime[:turbo_stream]
    @controller.response.body = '<turbo-stream action="update" target="foo"></turbo-stream>'
  end

  test 'append_session_flash_to_turbo_stream prepends notice streams' do
    @controller.flash[:notice] = 'Допис створено.'
    @controller.append_session_flash_to_turbo_stream

    assert_includes @controller.response.body, 'Допис створено.'
    assert_includes @controller.response.body, 'target="application-notice"'
    assert_includes @controller.response.body, 'target="application-alert"'
  end

  test 'append_session_flash_to_turbo_stream skips when flash frames already present' do
    @controller.flash[:notice] = 'Допис створено.'
    @controller.response.body = '<turbo-stream action="update" target="application-notice"></turbo-stream>'
    @controller.append_session_flash_to_turbo_stream

    assert_not_includes @controller.response.body, 'Допис створено.'
    assert_equal 1, @controller.response.body.scan('target="application-notice"').size
  end
end
