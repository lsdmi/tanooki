# frozen_string_literal: true

module Publications
  # Rails.cache keys for public tale lists and show pages.
  class PublicCache
    HIGHLIGHTS_LIMIT = 10
    SHOW_TTL = 1.hour
    LIST_TTL = 4.hours
    HIGHLIGHTS_KEY = "highlights_#{HIGHLIGHTS_LIMIT}".freeze
    EXCLUDING_HIGHLIGHTS_KEY = "publications_excluding_#{HIGHLIGHTS_LIMIT}".freeze
    POPULAR_BLOGS_KEY = 'popular_blogs'
    TOP_TALE_KEY = 'top_tale/v1'
    LIST_KEYS = [HIGHLIGHTS_KEY, EXCLUDING_HIGHLIGHTS_KEY, POPULAR_BLOGS_KEY, TOP_TALE_KEY].freeze

    def self.show_key(id_or_slug)
      "publication_#{id_or_slug}"
    end

    def self.write_show(key, publication)
      Rails.cache.write(key, publication, expires_in: SHOW_TTL)
    end

    def self.bust(publication)
      Rails.cache.delete(show_key(publication.id))
      Rails.cache.delete(show_key(publication.slug))
      previous_slug = publication.slug_previously_was
      Rails.cache.delete(show_key(previous_slug)) if previous_slug.present?
      LIST_KEYS.each { |key| Rails.cache.delete(key) }
    end
  end
end
