# frozen_string_literal: true

module Chapters
  # Thanks a live chapter, or takes the thanks back when the reader already gave it. The team behind the chapter
  # (and admins) cannot thank it.
  class ToggleThank
    Result = Data.define(:ok, :thanked, :thanks_count, :error)

    def self.call(...) = new(...).call

    def initialize(chapter:, user:)
      @chapter = chapter
      @user = user
    end

    def call
      return failure(:not_released) unless @chapter.public_visible?
      return failure(:own_work) if @user.manages_chapter?(@chapter)

      thanked = @chapter.with_lock do
        thank = ChapterThank.find_by(user: @user, chapter: @chapter)
        thank ? thank.destroy! : ChapterThank.create!(user: @user, chapter: @chapter)
        thank.nil?
      end
      success(thanked)
    rescue ActiveRecord::RecordNotUnique
      success(true)
    end

    private

    def success(thanked)
      Result.new(ok: true, thanked:, thanks_count: @chapter.reload.thanks_count, error: nil)
    end

    def failure(error)
      Result.new(ok: false, thanked: @chapter.thanked_by?(@user), thanks_count: @chapter.thanks_count, error:)
    end
  end
end
