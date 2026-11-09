# frozen_string_literal: true

module Contests
  # Live checklist for an accepted contest entry: chapters, completion, genre, rating.
  class RequirementsProgress
    Item = Data.define(:key, :label, :current, :required, :met?)

    def self.call(entry) = new(entry).call

    def initialize(entry)
      @entry = entry
      @contest = entry.contest
      @fiction = entry.fiction
    end

    def call
      return [] if fiction.blank?

      [
        chapters_item,
        completed_item,
        genre_item,
        rating_item
      ].compact
    end

    def all_met?
      items = call
      items.any? && items.all?(&:met?)
    end

    def judged_chapters
      @judged_chapters ||= JudgedChapters.call(contest:, fiction:).to_a
    end

    private

    attr_reader :entry, :contest, :fiction

    def chapters_item
      required = contest.min_chapters
      return if required.blank?

      current = judged_chapters.size
      Item.new(
        key: :chapters,
        label: I18n.t('contests.progress.chapters', count: required),
        current:,
        required:,
        met?: current >= required
      )
    end

    def completed_item
      return unless contest.requires_completed?

      met = fiction.completed_at.present?
      Item.new(
        key: :completed,
        label: I18n.t('contests.progress.completed'),
        current: met ? 1 : 0,
        required: 1,
        met?: met
      )
    end

    def genre_item
      genre = contest.required_genre
      return if genre.blank?

      met = fiction.genres.exists?(id: genre.id)
      Item.new(
        key: :genre,
        label: I18n.t('contests.progress.genre', name: genre.name),
        current: met ? 1 : 0,
        required: 1,
        met?: met
      )
    end

    def rating_item
      max = contest.max_content_rating
      return if max.blank?

      current = Fiction.content_ratings.fetch(fiction.content_rating)
      Item.new(
        key: :rating,
        label: I18n.t('contests.progress.rating', max: max),
        current:,
        required: max,
        met?: current <= max
      )
    end
  end
end
