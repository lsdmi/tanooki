# frozen_string_literal: true

module TagsHelper
  def main_state(tag)
    title_size = tag.title.size
    description_size = punch(tag.description.to_plain_text).size

    if title_size > 85 || (150 - (description_size + title_size)).negative?
      'hidden lg:block'
    else
      'hidden sm:block'
    end
  end

  def sweetalert(button_content, options = {})
    button_tag(
      button_content,
      data: options.merge(token: form_authenticity_token),
      class: "sweet-alert-button #{options[:button_class]}"
    ).html_safe
  end
end
