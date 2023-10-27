# frozen_string_literal: true

class ChapterScanlatorsManager
  attr_reader :scanlators_ids, :chapter

  def initialize(scanlators_ids, chapter)
    @scanlators_ids = scanlators_ids
    @chapter = chapter
  end

  def operate
    return if scanlators_ids.nil?

    create_chapter_scanlators
    destory_chapter_scanlators
  end

  private

  def create_chapter_scanlators
    scanlators_to_add = chapter_scanlators_ids - existing_scanlators_ids
    scanlators_to_add.each { |scanlator_id| chapter.chapter_scanlators.create(scanlator_id:) }
  end

  def destory_chapter_scanlators
    scanlators_to_remove = existing_scanlators_ids - chapter_scanlators_ids
    scanlators_to_remove.each { |scanlator_id| chapter.chapter_scanlators.find_by(scanlator_id:).destroy }
  end

  def existing_scanlators_ids
    chapter.scanlators.ids
  end

  def chapter_scanlators_ids
    scanlators_ids.reject(&:empty?).map(&:to_i)
  end
end
