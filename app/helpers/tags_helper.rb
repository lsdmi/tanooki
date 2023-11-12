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
  # button_content - button content TEXT | image | etc
  # message - Title message displayed on alert
  # type - 0 = OK or 1 = OKCANCEL
  # description - smaller message displayed under main
  # url - redirect url when pressed OK default Nil
  # ok_button_text - text displayed on Ok button
  # cancel_button_text - text displayed on Cancel button
  # button_class - styles
  # async_fetch - url to call in case of Ok
  # async_fetch_method - method used by fetch DEFAULT POST
  # async_fetch_after_deletetag - removes tag by specified id if call was successful
  # )
  def sweetalert(button_content,
                 message:,
                 type: 0,
                 description: " ",
                 url: "*",
                 ok_button_text: "Так!",
                 cancel_button_text: "Ні в якому разі!",
                 button_class: "",
                 async_fetch: "",
                 async_fetch_method: "",
                 async_fetch_after_deletetag: "")
    script_tag = ''
    unless defined?(@inserted)
      @inserted = true
      script_tag = javascript_include_tag 'sweetalert'
    end

    button = button_tag(button_content,
                        data: { message: message,
                                type: type,
                                description: description,
                                url: url,
                                ok_button_text: ok_button_text,
                                cancel_button_text: cancel_button_text,
                                async_fetch: async_fetch,
                                method: async_fetch_method,
                                delete_after: async_fetch_after_deletetag,
                                auth_token: form_authenticity_token },

                        class: "sweet-alert-button #{button_class}")

    "#{script_tag} #{button}".html_safe
  end
end
