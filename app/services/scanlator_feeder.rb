# frozen_string_literal: true

class ScanlatorFeeder
  attr_reader :fiction_size, :scanlator

  def initialize(fiction_size:, scanlator:)
    @fiction_size = fiction_size
    @scanlator = scanlator
  end

  def call
    Rails.cache.fetch("scanlator_#{scanlator.slug}_feed", expires_in: 2.hours) do
      (fiction_activities + chapter_activities).sort_by(&:created_at).last(size).reverse
    end
  end

  private

  def chapter_activities
    scanlator.chapters.includes(:fiction).order(created_at: :desc).limit(size)
  end

  def fiction_activities
    scanlator.fictions.includes(:genres).order(created_at: :desc).limit(size)
  end

  def size
    fiction_size < 7 ? 5 : 5 + (fiction_size / 3).ceil
  end
end
