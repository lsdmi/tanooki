# frozen_string_literal: true

module FictionsHelper
  def fiction_author(fiction)
    sanitize("
      #{fiction.author} #{"(переклад <strong>#{fiction.translator}</strong>)" if fiction.translator.present?}
    ")
  end
end
