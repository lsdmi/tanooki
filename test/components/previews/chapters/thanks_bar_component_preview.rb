# frozen_string_literal: true

module Chapters
  # Uses the development database: a live chapter and a reader who does not manage it.
  class ThanksBarComponentPreview < ViewComponent::Preview
    # @label Reader
    def reader
      render ThanksBarComponent.new(chapter: sample_chapter, user: sample_reader)
    end

    # @label Guest
    def guest
      render ThanksBarComponent.new(chapter: sample_chapter, user: nil)
    end

    # @label Team / owner
    def owner
      render ThanksBarComponent.new(chapter: sample_chapter, user: sample_owner)
    end

    private

    def sample_chapter
      chapter = Chapter.released.includes(:scanlators, :users).order(created_at: :desc).first
      raise 'Add a published chapter to preview Chapters::ThanksBarComponent.' unless chapter

      chapter
    end

    def sample_reader
      User.where.not(id: sample_chapter.users.select(:id)).where(admin: false).first ||
        User.where(admin: false).first
    end

    def sample_owner
      sample_chapter.users.first || User.find_by(admin: true)
    end
  end
end
