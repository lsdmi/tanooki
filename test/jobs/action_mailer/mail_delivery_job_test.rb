# frozen_string_literal: true

require 'test_helper'

module ActionMailer
  class MailDeliveryJobTest < ActiveJob::TestCase
    test 'retries SMTP timeouts instead of failing the job' do
      handled = ActionMailer::MailDeliveryJob.rescue_handlers.map(&:first)

      assert_includes handled, 'Net::ReadTimeout'
      assert_includes handled, 'Net::OpenTimeout'
    end
  end
end
