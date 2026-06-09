# frozen_string_literal: true

module Layout
  # Builds a +button_tag+ wired for SweetAlert2 (+data-*+ and CSRF); used with +shared/sweet_alert+
  # and +application.js+.
  module SweetAlertHelper
    def sweet_alert_button(button_content, options = {})
      button_tag(
        button_content,
        data: options.merge(token: form_authenticity_token),
        class: ['sweet-alert-button', options[:button_class]].compact.join(' ')
      )
    end
  end
end
