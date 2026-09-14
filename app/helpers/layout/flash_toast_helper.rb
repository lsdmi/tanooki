# frozen_string_literal: true

module Layout
  # Hidden payload that Stimulus converts into a flash toast.
  module FlashToastHelper
    def flash_toast_payload(message, type:)
      return if message.blank?

      tag.div(
        hidden: true,
        data: {
          controller: 'flash-toast',
          flash_toast_type_value: type,
          flash_toast_message_value: message
        }
      )
    end
  end
end
