# frozen_string_literal: true

module Chapters
  # Who may add chapters to a fiction.
  #
  # GET new: admin, existing fiction team, or any scanlator member (alternative-translation CTA).
  # POST create: admin, existing fiction team, or poster selects at least one of their own teams.
  # Neither for a licensed fiction, admins included.
  class Authorization
    attr_reader :user, :fiction, :scanlator_ids

    def initialize(user, fiction, scanlator_ids: nil)
      @user = user
      @fiction = fiction
      @scanlator_ids = normalize_scanlator_ids(scanlator_ids)
    end

    def new?
      open_fiction? && (user.admin? || user.manages_fiction?(fiction) || user.scanlators.any?)
    end

    def create?
      return false unless open_fiction?

      return true if user.admin?
      return true if user.manages_fiction?(fiction)
      return false unless user.scanlators.any?

      user.scanlators.ids.intersect?(scanlator_ids)
    end

    def licensed?
      fiction.present? && fiction.licensed?
    end

    private

    def open_fiction?
      fiction.present? && !fiction.licensed?
    end

    def normalize_scanlator_ids(ids)
      Array(ids).compact_blank.map(&:to_i).reject(&:zero?)
    end
  end
end
