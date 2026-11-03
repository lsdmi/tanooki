# frozen_string_literal: true

module Contests
  # Contest page Stage hero: title, tagline, phase, primary/secondary actions, optional cover.
  class HeroComponent < ViewComponent::Base
    include Meta::CoverUrlsHelper

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
      when :results then contest.results_published_at
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
