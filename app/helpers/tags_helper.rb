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
end
