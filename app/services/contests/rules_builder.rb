# frozen_string_literal: true

module Contests
  # Builds a publish-time rules snapshot from contest fields + general rules locale (§7.7.3).
  class RulesBuilder
    include RulesBlocks

    def self.snapshot(contest) = new(contest).snapshot
    def self.append_change!(contest, reason:, at: Time.current) = new(contest).append_change!(reason:, at:)

    def initialize(contest)
      @contest = contest
    end

    def snapshot
      snapshot_header.merge(snapshot_sections)
    end

    def append_change!(reason:, at: Time.current)
      raise ArgumentError, 'reason required' if reason.to_s.strip.blank?

      changes = Array(contest.rule_changes).map(&:dup)
      changes << { 'at' => at.iso8601, 'reason' => reason.to_s.strip }
      contest.update!(rule_changes: changes, rules_snapshot: snapshot)
    end

    private

    attr_reader :contest

    def snapshot_header
      {
        'version' => 1,
        'captured_at' => Time.current.iso8601,
        'general_rules_digest' => general_rules_digest,
        'summary' => summary_facts
      }
    end

    def snapshot_sections
      {
        'requirements' => requirements_lines,
        'dates' => dates_block,
        'scoring' => scoring_block,
        'prizes' => prizes_block,
        'how_to_join' => how_to_join_lines,
        'extra_rules_html' => contest.rules.body.to_s.presence
      }
    end

    def general_rules_digest
      Digest::SHA256.hexdigest(I18n.t('contests.rules').to_json)
    end

    def summary_facts
      {
        'deadline' => contest.submissions_close_at.iso8601,
        'fee' => I18n.t('contests.show.facts.fee_value'),
        'first_prize' => first_prize_cash,
        'who' => I18n.t('contests.show.facts.who_value'),
        'kind' => I18n.t("contests.kinds.#{contest.kind}"),
        'genre_rating' => genre_rating_line
      }
    end

    def requirements_lines
      [new_work_line, chapters_line, words_line, genre_line, rating_line, completed_line].compact
    end

    def new_work_line
      I18n.t('contests.show.requirements.new_work') if contest.requires_new_work?
    end

    def chapters_line
      return unless contest.min_chapters

      I18n.t('contests.show.requirements.chapters', count: contest.min_chapters)
    end

    def words_line
      I18n.t('contests.show.requirements.words', count: contest.min_words) if contest.min_words
    end

    def genre_line
      return unless contest.required_genre

      I18n.t('contests.show.requirements.genre', name: contest.required_genre.name)
    end

    def rating_line
      I18n.t('contests.show.requirements.rating', rating: contest.max_content_rating)
    end

    def completed_line
      I18n.t('contests.show.requirements.completed') if contest.requires_completed?
    end

    def first_prize_cash
      contest.prizes.place.order(:place).pick(:cash_uah)
    end

    def genre_rating_line
      parts = []
      parts << contest.required_genre.name if contest.required_genre
      parts << "#{contest.max_content_rating}+"
      parts.join(' · ')
    end
  end
end
