# frozen_string_literal: true

# Devise mailer; templates live under users/mailer.
class UserMailer < Devise::Mailer
  def headers_for(action, opts)
    super.merge!({ template_path: 'users/mailer' })
  end
end
