# frozen_string_literal: true

module FictionsHelper
  def fiction_author(fiction)
    if fiction.translator.present?
      sanitize("Перекладач: <strong>#{fiction.translator}</strong>")
    else
      sanitize("Оригінальна робота <strong>#{fiction.author}</strong>")
    end
  end
end
