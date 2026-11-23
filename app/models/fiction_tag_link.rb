# frozen_string_literal: true

# Join between a fiction and one of its FictionTags; keeps FictionTag#fictions_count current.
class FictionTagLink < ApplicationRecord
  belongs_to :fiction
  belongs_to :fiction_tag, counter_cache: :fictions_count

  validates :fiction_tag_id, uniqueness: { scope: :fiction_id }
  validate :within_fiction_limit, on: :create

  private

  def within_fiction_limit
    return if fiction_id.nil?
    return if self.class.where(fiction_id:).count < FictionTag::MAX_PER_FICTION

    errors.add(:fiction, :too_many_tags, count: FictionTag::MAX_PER_FICTION)
  end
end
