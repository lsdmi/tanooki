# frozen_string_literal: true

# One pair of fictions an admin decided are not the same work.
# The smaller id is always `fiction_id`, so a pair is stored once.
class FictionDuplicateDismissal < ApplicationRecord
  belongs_to :fiction, inverse_of: false
  belongs_to :other_fiction, class_name: 'Fiction', inverse_of: false
  belongs_to :user, optional: true

  validates :user, presence: true, on: :create
  validate :ordered_ids

  def self.dismiss(fictions, user:)
    ids = fictions.map(&:id).uniq.sort
    ids.combination(2) { |left, right| remember(left, right, user) }
  end

  def self.pairs
    pluck(:fiction_id, :other_fiction_id).to_set
  end

  def self.remember(left, right, user)
    find_or_create_by!(fiction_id: left, other_fiction_id: right) { |row| row.user = user }
  end
  private_class_method :remember

  private

  def ordered_ids
    return if fiction_id.present? && other_fiction_id.present? && fiction_id < other_fiction_id

    errors.add(:other_fiction_id, :invalid)
  end
end
