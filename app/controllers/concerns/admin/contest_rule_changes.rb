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
    TIME_KEYS = %w[announced_at submissions_open_at submissions_close_at judging_close_at].freeze
    BOOLEAN_KEYS = %w[requires_new_work requires_completed].freeze
    INTEGER_KEYS = %w[
      min_chapters min_words max_words judged_word_cap max_content_rating
      max_entries_per_user jury_weight prize_pool_uah
    ].freeze
    PRIZE_TEXT_KEYS = %w[title kind perks].freeze
    PRIZE_INTEGER_KEYS = %w[place position cash_uah unlock_at_uah].freeze

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
      SETTINGS_KEYS.any? { |key| assigned.key?(key) && setting_changed?(key, assigned[key]) } ||
        prizes_changed?(assigned['prizes_attributes'])
    end

    def setting_changed?(key, incoming)
      current = @contest.public_send(key)
      if TIME_KEYS.include?(key) then !same_minute?(current, incoming)
      elsif BOOLEAN_KEYS.include?(key) then boolean_value(current) != boolean_value(incoming)
      elsif INTEGER_KEYS.include?(key) then integer_or_nil(current) != integer_or_nil(incoming)
      else current.to_s != incoming.to_s
      end
    end

    def same_minute?(current, incoming)
      clock_minute(current) == clock_minute(incoming)
    end

    def clock_minute(value)
      return if value.blank?

      time = value.is_a?(String) ? Time.zone.parse(value) : value
      time&.change(sec: 0)
    end

    def boolean_value(value)
      ActiveModel::Type::Boolean.new.cast(value)
    end

    def integer_or_nil(value)
      return if value.blank?

      value.to_i
    end

    def prizes_changed?(attrs)
      return false if attrs.blank?

      rows = attrs.each_value.map { |row| row.to_h.stringify_keys }
      existing = @contest.prizes.index_by { |prize| prize.id.to_s }
      removed_prize?(rows, existing) || rows.any? { |row| prize_row_changed?(existing[row['id'].to_s], row) }
    end

    def removed_prize?(rows, existing)
      rows.any? { |row| boolean_value(row['_destroy']) } ||
        (existing.keys - rows.filter_map { |row| row['id'].presence }).any?
    end

    def prize_row_changed?(prize, row)
      return true if prize.nil?

      PRIZE_TEXT_KEYS.any? { |key| prize.public_send(key).to_s != row[key].to_s } ||
        PRIZE_INTEGER_KEYS.any? { |key| integer_or_nil(prize.public_send(key)) != integer_or_nil(row[key]) }
    end
  end
end
