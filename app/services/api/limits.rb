# frozen_string_literal: true

module Api
  # Caps on what one token can do to live chapters, plus the site-wide write switch.
  # `API_WRITES_ENABLED=false` stops writes for every process. `stop_writes!` stops them
  # immediately through the cache, with no deploy.
  class Limits
    UNPUBLISHES_PER_DAY = 5
    PUBLISHED_EDITS_PER_HOUR = 30
    PUBLISHED_EDITS_PER_DAY = 200
    CREATES_PER_DAY = 100
    MIN_PUBLISHED_CHARACTERS = 500
    MAX_BLOCKS = 50
    WRITES_CACHE_KEY = 'api/v1/writes_enabled'

    def self.writes_enabled?
      return false if ENV['API_WRITES_ENABLED'] == 'false'

      Rails.cache.read(WRITES_CACHE_KEY) != false
    end

    def self.stop_writes!
      Rails.cache.write(WRITES_CACHE_KEY, false)
    end

    def self.allow_writes!
      Rails.cache.delete(WRITES_CACHE_KEY)
    end

    def self.counter_key(kind, user, period)
      "api/limits/#{kind}/#{user.id}/#{period}"
    end

    def self.refuse_published_rewrite!(before_html, after_html)
      after_text = plain_text(after_html)
      raise Error.new('rewrite_too_short', :unprocessable_entity) if after_text.length < MIN_PUBLISHED_CHARACTERS

      before_text = plain_text(before_html)
      return if before_text.empty? || kept_enough?(before_text, after_text)

      raise Error.new('rewrite_too_small', :unprocessable_entity)
    end

    def self.refuse_too_many_blocks!(count)
      return if count.to_i <= MAX_BLOCKS

      raise Error.new('too_many_blocks', :unprocessable_entity)
    end

    def self.plain_text(html)
      ActionController::Base.helpers.strip_tags(html.to_s).squish
    end

    def self.kept_enough?(before_text, after_text)
      after_text.length * 10 >= before_text.length * 7
    end

    private_class_method :kept_enough?

    def initialize(user)
      @user = user
    end

    def record_create!
      ensure_writes!
      count = bump(:create, Date.current, 26.hours)
      raise Error.new('creates_cap', :too_many_requests) if count > CREATES_PER_DAY

      count
    end

    def record_unpublish!
      ensure_writes!
      count = bump(:unpublish, Date.current, 26.hours)
      raise Error.new('unpublish_cap', :too_many_requests) if count > UNPUBLISHES_PER_DAY

      count
    end

    def record_published_edit!
      ensure_writes!
      hour = bump(:published_edit_hour, Time.current.strftime('%Y%m%d%H'), 2.hours)
      day = bump(:published_edit_day, Date.current, 26.hours)
      over = hour > PUBLISHED_EDITS_PER_HOUR || day > PUBLISHED_EDITS_PER_DAY
      raise Error.new('published_edit_cap', :too_many_requests) if over

      hour
    end

    private

    def ensure_writes!
      return if self.class.writes_enabled?

      raise Error.new('writes_disabled', :forbidden)
    end

    def bump(kind, period, expires_in)
      Rails.cache.increment(self.class.counter_key(kind, user, period), 1, expires_in:)
    end

    attr_reader :user
  end
end
