# frozen_string_literal: true

# Free-form theme or trope on a fiction (переродження, юрі, школа) — not a Genre and not a publication Tag.
class FictionTag < ApplicationRecord
  extend FriendlyId

  MAX_NAME_LENGTH = 40
  MAX_PER_FICTION = 10

  friendly_id :name

  enum :status, { active: 'active', hidden: 'hidden' }, default: :active, validate: true

  # Remember the works before dependent: :destroy drops the links, so they can be refreshed after commit.
  before_destroy :remember_fiction_ids
  has_many :fiction_tag_links, dependent: :destroy

  after_commit :refresh_fictions, on: %i[update destroy], if: :reader_facing_change?

  normalizes :name, with: ->(value) { FictionTags::Normalizer.name(value) }, apply_to_nil: false

  validates :name, presence: true, length: { maximum: MAX_NAME_LENGTH }, uniqueness: { case_sensitive: false }
  validate :name_slug_present_and_unique, if: -> { name.present? && (new_record? || will_save_change_to_name?) }

  def normalize_friendly_id(value) = FictionTags::Normalizer.slug(value)

  private

  def remember_fiction_ids
    @fiction_ids = fiction_tag_links.pluck(:fiction_id)
  end

  def reader_facing_change?
    destroyed? || saved_changes.keys.intersect?(%w[name status explicit])
  end

  def refresh_fictions
    FictionTags::RefreshFictions.call(@fiction_ids || fiction_tag_links.pluck(:fiction_id))
  end

  def name_slug_present_and_unique
    candidate = FictionTags::Normalizer.slug(name)

    if candidate.blank?
      errors.add(:name, :invalid)
    elsif slug_taken?(candidate)
      errors.add(:name, :taken) unless errors.of_kind?(:name, :taken)
    end
  end

  def slug_taken?(candidate)
    self.class.where.not(id:).exists?(slug: candidate)
  end
end
