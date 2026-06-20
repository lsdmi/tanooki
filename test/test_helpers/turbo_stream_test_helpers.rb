# frozen_string_literal: true

module TurboStreamTestHelpers
  def assert_turbo_stream_flash_notice(message)
    assert_includes response.body, message
    assert_select 'turbo-stream[action="update"][target="application-notice"]'
    assert_select 'turbo-stream[action="update"][target="application-alert"]'
  end
end

ActiveSupport.on_load(:action_dispatch_integration_test) { include TurboStreamTestHelpers }
