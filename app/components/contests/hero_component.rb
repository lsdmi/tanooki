# frozen_string_literal: true

module Contests
  # Contest page hero. Cover, veil, and type match the fictions index showcase.
  class HeroComponent < ViewComponent::Base
    def initialize(contest:, presenter:)
      super()
      @contest = contest
      @presenter = presenter
    end

    private

    attr_reader :contest, :presenter

    def phase_label
      t("contests.phases.#{presenter.phase}")
    end

    def archive_stamp?
      presenter.phase.in?(%i[results cancelled])
    end

    def archive_stamp
      year = contest.results_published_at&.year || contest.submissions_close_at&.year
      return t('contests.show.hero.archive_stamp') if year.blank?

      t('contests.show.hero.archive_stamp_year', year:)
    end

    def deadline_line
      if presenter.phase == :submissions
        t('contests.show.hero.deadline_timer', date: l(contest.submissions_close_at, format: :long))
      else
        next_date = next_milestone
        return if next_date.blank?

        t('contests.show.hero.next_date', date: l(next_date, format: :long))
      end
    end

    def next_milestone
      case presenter.phase
      when :announced then contest.submissions_open_at
      when :judging, :awaiting_results then contest.results_published_at || contest.judging_close_at
      end
    end

    def primary
      presenter.primary_action
    end

    def secondary
      presenter.secondary_action
    end

    def action_label(action)
      t(action[:label_key], **action.fetch(:label_args, {}))
    end

    def cover?
      contest.cover.attached?
    end
  end
end
