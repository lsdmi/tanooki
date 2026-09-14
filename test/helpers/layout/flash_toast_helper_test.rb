# frozen_string_literal: true

require 'test_helper'

module Layout
  class FlashToastHelperTest < ActionView::TestCase
    include FlashToastHelper

    test 'payload is hidden and wires stimulus controller' do
      html = flash_toast_payload('Полицю дадано', type: 'notice')

      assert_includes html, 'hidden'
      assert_includes html, 'data-controller="flash-toast"'
      assert_includes html, 'data-flash-toast-type-value="notice"'
    end

    test 'payload includes the message value' do
      html = flash_toast_payload('Полицю дадано', type: 'notice')

      assert_includes html, 'data-flash-toast-message-value="Полицю дадано"'
    end

    test 'payload escapes html in the message value' do
      html = flash_toast_payload('<b>oops</b>', type: 'alert')

      assert_includes html, 'data-flash-toast-type-value="alert"'
      assert_includes html, '&lt;b&gt;oops&lt;/b&gt;'
      assert_not_includes html, 'data-flash-toast-message-value="<b>oops</b>"'
    end

    test 'blank message renders nothing' do
      assert_nil flash_toast_payload('   ', type: 'notice')
      assert_nil flash_toast_payload(nil, type: 'alert')
    end
  end
end
