# frozen_string_literal: true

module Layout
  # Builds a +button_tag+ wired to +sweet_alert_controller+ for Turbo-safe delete confirms.
  module SweetAlertHelper
    def sweet_alert_button(button_content, options = {})
      button_tag(
        button_content,
        type: 'button',
        data: sweet_alert_data_attrs(options),
        class: ['sweet-alert-button', options[:button_class]].compact.join(' ')
      )
    end

    def sweet_alert_data_attrs(options)
      {
        controller: 'sweet-alert',
        action: 'click->sweet-alert#confirm',
        sweet_alert_message_value: options[:message],
        sweet_alert_description_value: options[:description],
        sweet_alert_url_value: options[:url],
        sweet_alert_tag_id_value: options[:tag_id]
      }.compact
    end
  end
end
