# frozen_string_literal: true

module Admin
  # Rule-change reason handling for published contests in Admin::ContestsController.
  module ContestRuleChanges
    SETTINGS_KEYS = %w[
      announced_at submissions_open_at submissions_close_at judging_close_at
      requires_new_work requires_completed min_chapters min_words max_words judged_word_cap
      judged_chapters_scope max_content_rating max_entries_per_user jury_weight
      prize_pool_uah criteria
    ].freeze

    private

    def published?
      @contest.published_at.present?
    end

    def rule_change_reason_missing?
      published? && settings_changed? && params[:rule_change_reason].to_s.strip.blank?
    end

    def render_rule_change_reason_required
      @contest.assign_attributes(contest_params)
      flash.now[:alert] = t('admin.contests.notices.rule_change_reason_required')
      render :edit, status: :unprocessable_content
    end

    def append_rule_change!
      return unless published? && params[:rule_change_reason].to_s.strip.present?

      ::Contests::RulesBuilder.append_change!(@contest, reason: params[:rule_change_reason])
    end

    def settings_changed?
      assigned = contest_params.to_h
      SETTINGS_KEYS.any? { |key| assigned.key?(key) && @contest.public_send(key).to_s != assigned[key].to_s } ||
        assigned.key?('prizes_attributes')
    end
  end
end
