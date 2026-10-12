# frozen_string_literal: true

module Chapters
  # The chapter-list team a reader last picked, per fiction, kept in one cookie.
  class TeamChoice
    KEY = :chapter_teams
    LIMIT = 30

    def self.read(cookies, fiction_id)
      choices(cookies)[fiction_id.to_s]
    end

    def self.write(cookies, fiction_id, scanlator_id)
      picked = choices(cookies)
      picked.delete(fiction_id.to_s)
      picked[fiction_id.to_s] = scanlator_id.to_s if scanlator_id.present?
      cookies[KEY] = cookie(picked)
    end

    def self.choices(cookies)
      JSON.parse(cookies[KEY].to_s)
    rescue JSON::ParserError, TypeError
      {}
    end
    private_class_method :choices

    def self.cookie(picked)
      {
        value: picked.to_a.last(LIMIT).to_h.to_json,
        expires: 1.year.from_now,
        httponly: true,
        same_site: :lax
      }
    end
    private_class_method :cookie
  end
end
