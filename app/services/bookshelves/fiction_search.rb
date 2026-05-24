# frozen_string_literal: true

module Bookshelves
  # JSON options for Slim Select on bookshelf forms (avoids loading all fictions).
  class FictionSearch
    LIMIT = 30

    class << self
      def call(query:)
        stripped = query.to_s.strip
        scope = Fiction.order(:title)

        if stripped.present?
          pattern = "%#{ActiveRecord::Base.sanitize_sql_like(stripped)}%"
          scope = scope.where(
            'title LIKE :q OR alternative_title LIKE :q OR english_title LIKE :q OR author LIKE :q',
            q: pattern
          )
        end

        scope.limit(LIMIT).map { |fiction| option_for(fiction) }
      end

      private

      def option_for(fiction)
        { text: fiction.title, value: fiction.id.to_s }
      end
    end
  end
end
