# frozen_string_literal: true

# SMTP (Zoho) occasionally stalls or drops the connection. Devise mail (confirmation, password reset) goes through
# ActionMailer::MailDeliveryJob, which has no retry of its own, so one timeout used to lose the email for good.
Rails.application.config.after_initialize do
  ActionMailer::MailDeliveryJob.retry_on(
    Net::ReadTimeout, Net::OpenTimeout, Errno::ECONNRESET, EOFError,
    wait: :polynomially_longer, attempts: 5
  )
end
