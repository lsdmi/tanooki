# frozen_string_literal: true

module Fictions
  # Fiction, chapter, and reader rows for merge tests.
  module MergeFixture
    def build_fiction(slug, title)
      fiction = Fiction.new(
        slug:, title:, author: 'Автор', views: 0,
        description: 'Опис твору достатньої довжини для тесту.'
      )
      fiction.save!(validate: false)
      fiction
    end

    def build_chapter(fiction, slug, number, published_at: 1.hour.ago)
      chapter = Chapter.new(
        slug:, title: 'Розділ', number:, fiction:, published_at:,
        user: users(:user_one), status: 'published'
      )
      chapter.save!(validate: false)
      chapter
    end

    def build_read
      ReadingChapterRead.create!(
        user: users(:user_one), fiction: @source, chapter: @chapter,
        completed_at: Time.current, source: 'scroll'
      )
    end

    def build_progress(fiction, user, chapter, updated_at:)
      progress = ReadingProgress.new(fiction:, user:, chapter:, status: :active)
      progress.save!(validate: false)
      progress.update!(updated_at:)
      progress
    end

    def build_scanlator(slug)
      scanlator = Scanlator.new(title: slug, slug:, description: 'Команда перекладу')
      scanlator.save!(validate: false)
      scanlator
    end
  end
end
