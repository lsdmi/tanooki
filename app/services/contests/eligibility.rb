# frozen_string_literal: true

module Contests
  # Whether a user may submit (optionally a specific fiction) to a contest.
  class Eligibility
    attr_reader :user, :contest, :fiction, :reasons

    def initialize(user:, contest:, fiction: nil)
      @user = user
      @contest = contest
      @fiction = fiction
      @reasons = []
    end

    def allowed?
      evaluate
      reasons.empty?
    end

    def reason_messages
      evaluate
      reasons.map { |key| I18n.t("contests.eligibility.#{key}") }
    end

    private

    def evaluate
      return if @evaluated

      @evaluated = true
      @reasons = []
      check_phase
      check_email
      check_juror
      check_entry_limit
      check_fiction if fiction.present?
    end

    def check_fiction
      check_manages_fiction
      check_already_entered
      check_requires_new_work
      check_required_genre
      check_content_rating
    end

    def check_phase
      return if contest.submissions_open?

      reasons << :wrong_phase
    end

    def check_email
      return if user&.confirmed?

      reasons << :email_unconfirmed
    end

    def check_juror
      return if user.blank?
      return unless contest.jurors.exists?(user_id: user.id)

      reasons << :juror_or_organizer
    end

    def check_entry_limit
      return if user.blank?

      return if limited_entries.count < contest.max_entries_per_user

      reasons << :entry_limit_reached
    end

    def limited_entries
      active = contest.entries.active.where(submitter_id: user.id)
      fiction&.persisted? ? active.where.not(fiction_id: fiction.id) : active
    end

    def check_manages_fiction
      return if user&.manages_fiction?(fiction)

      reasons << :does_not_manage_fiction
    end

    def check_already_entered
      existing = contest.entries.find_by(fiction_id: fiction.id)
      return if existing.blank?
      return if existing.rejected? || existing.withdrawn?

      reasons << :already_entered
    end

    def check_requires_new_work
      return unless contest.requires_new_work?
      return if fiction.created_at >= contest.submissions_open_at

      reasons << :requires_new_work
    end

    def check_required_genre
      return if contest.required_genre_id.blank?
      return if fiction.genres.exists?(id: contest.required_genre_id)

      reasons << :missing_required_genre
    end

    def check_content_rating
      rating = Fiction.content_ratings.fetch(fiction.content_rating)
      return if rating <= contest.max_content_rating

      reasons << :content_rating_too_high
    end
  end
end
