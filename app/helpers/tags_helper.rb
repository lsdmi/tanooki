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

  def tag_formatter(tag)
    tag.name.downcase.gsub(/[\s,!\-]/, '_')
  end




  # sweetalert(
  # button_text - text on inserted button
  # message - Title message displayed on alert
  # type - 0 = OK or 1 = OKCANCEL
  # description - smalles message displayed under main
  # url - redirect url when pressed OK default Nil
  # ok_button_text - text displayed on Ok button
  # cancel_button_text - text displayed on Cancel button
  # )
  def sweetalert(button_text, message:, type: 0, description: " ", url: "*", ok_button_text: "Так!", cancel_button_text: "Ні в якому разі!")
    script_tag = ''
    unless defined?(@inserted)
      @inserted = true
      script_tag = javascript_include_tag 'sweetalert'
    end

    button = button_tag(button_text, onclick: "sweetalert('#{message}', '#{url}', '#{description}', #{type}, '#{ok_button_text}', '#{cancel_button_text}')")

    "#{script_tag} #{button}".html_safe
  end
end
