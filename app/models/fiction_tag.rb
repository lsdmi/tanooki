# frozen_string_literal: true

# Free-form theme or trope on a fiction (переродження, юрі, школа) — not a Genre and not a publication Tag.
class FictionTag < ApplicationRecord
  extend FriendlyId

  MAX_NAME_LENGTH = 40
  MAX_PER_FICTION = 10

  friendly_id :name

  enum :status, { active: 'active', hidden: 'hidden' }, default: :active, validate: true

  has_many :fiction_tag_links, dependent: :destroy
  has_many :fictions, through: :fiction_tag_links

  normalizes :name, with: ->(value) { FictionTags::Normalizer.name(value) }, apply_to_nil: false

  validates :name, presence: true, length: { maximum: MAX_NAME_LENGTH }, uniqueness: { case_sensitive: false }
  validate :name_slug_present_and_unique, if: -> { name.present? && (new_record? || will_save_change_to_name?) }

  def normalize_friendly_id(value) = FictionTags::Normalizer.slug(value)

  private

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
