# frozen_string_literal: true

module TagsHelper
  def sweetalert(button_content, options = {})
    button_tag(
      button_content,
      data: options.merge(token: form_authenticity_token),
      class: "sweet-alert-button #{options[:button_class]}"
    ).html_safe
  end
end
