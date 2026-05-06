# frozen_string_literal: true

module Reading
  # Invalidates reading-progress-related cache keys for a user and a fiction's stats/ranks.
  class ProgressCacheInvalidation
    def initialize(user, fiction)
      @user = user
      @fiction = fiction
    end

    def clear
      clear_user_caches
      clear_fiction_caches
    end

    private

    def clear_user_caches
      sections = ReadingProgress.statuses.keys
      sections.each do |section|
        Rails.cache.delete("user:#{@user.id}:related_fictions:#{section}")
        Rails.cache.delete("user:#{@user.id}:favourite_translators:#{section}")
      end
      Rails.cache.delete("user:#{@user.id}:reading_history")
    end

    def clear_fiction_caches
      Rails.cache.delete("fiction-#{@fiction.slug}-stats")
      Rails.cache.delete("fiction-#{@fiction.slug}-ranks")
    end
  end
end
