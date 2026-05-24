# frozen_string_literal: true

# Base mailer: shared layout and default sender for all mailers.
class ApplicationMailer < ActionMailer::Base
  default from: 'from@example.com'
  layout 'mailer'
end
