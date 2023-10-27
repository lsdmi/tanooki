# frozen_string_literal: true

class FictionScanlatorsManager
  attr_reader :scanlators_ids, :fiction

  def initialize(scanlators_ids, fiction)
    @scanlators_ids = scanlators_ids
    @fiction = fiction
  end

  def operate
    return if scanlators_ids.nil?

    create_fiction_scanlators
    destory_fiction_scanlators
  end

  private

  def create_fiction_scanlators
    scanlators_to_add = fiction_scanlators_ids - existing_scanlators_ids
    scanlators_to_add.each { |scanlator_id| fiction.fiction_scanlators.create(scanlator_id:) }
  end

  def destory_fiction_scanlators
    scanlators_to_remove = existing_scanlators_ids - fiction_scanlators_ids
    scanlators_to_remove.each { |scanlator_id| fiction.fiction_scanlators.find_by(scanlator_id:).destroy }
  end

  def existing_scanlators_ids
    fiction.scanlators.ids
  end

  def fiction_scanlators_ids
    scanlators_ids.reject(&:empty?).map(&:to_i)
  end
end
