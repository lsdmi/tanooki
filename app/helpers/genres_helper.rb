# frozen_string_literal: true

module GenresHelper
  def genre_formatter(genre)
    genre.name.downcase.gsub(/[\s,!\-]/, '_')
  end
end
