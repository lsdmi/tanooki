# frozen_string_literal: true

module Reading
  # Invalidates reading-progress caches for a user and a fiction.
  #
  # #clear_resume: an engaged event moved the cursor on an existing library row. Only «Читати далі» changed,
  # so related fictions, favourite translators and fiction stats/ranks stay cached.
  # #clear: completion, status change, destroy or a new library row. Library membership or counts may change.
  class ProgressCacheInvalidation
    def initialize(user, fiction)
      @user = user
      @fiction = fiction
    end

    def clear_resume
      clear_reading_history
    end

    def clear
      clear_user_caches
      clear_fiction_caches
    end

    private

    def clear_reading_history
      Rails.cache.delete("user:#{@user.id}:reading_history")
    end

    def clear_user_caches
      ReadingProgress.statuses.each_key do |section|
        Rails.cache.delete("user:#{@user.id}:related_fictions:#{section}")
        Rails.cache.delete("user:#{@user.id}:favourite_translators:#{section}")
      end
      clear_reading_history
    end

    def clear_fiction_caches
      Rails.cache.delete("fiction-#{@fiction.slug}-stats")
      Rails.cache.delete("fiction-#{@fiction.slug}-ranks")
    end
  end
end
