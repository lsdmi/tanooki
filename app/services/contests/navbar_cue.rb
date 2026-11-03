# frozen_string_literal: true

module Contests
  # Ranobe mega-menu cue: Contests subtitle + hot indicator for announced/submissions.
  class NavbarCue
    Cue = Data.define(:subtitle, :hot?, :cache_digest)

    HOT_PHASES = %i[announced submissions].freeze

    def self.call = new.call

    def call
      contest = featured_contest
      phase = contest&.phase
      Cue.new(
        subtitle: subtitle_for(contest, phase),
        hot?: HOT_PHASES.include?(phase),
        cache_digest: [contest&.id, phase, contest&.submissions_close_at&.to_i].join(':')
      )
    end

    private

    def featured_contest
      hub = HubPresenter.new
      hub.featured || Contest.archived.order(Arel.sql(HubPresenter::ARCHIVE_ORDER_SQL)).first
    end

    def subtitle_for(contest, phase)
      return I18n.t('contests.nav.subtitle.idle') if contest.blank?

      case phase
      when :announced then dated_subtitle(:announced, contest, contest.submissions_open_at)
      when :submissions then dated_subtitle(:submissions, contest, contest.submissions_close_at)
      else I18n.t('contests.nav.subtitle.archive')
      end
    end

    def dated_subtitle(key, contest, date)
      I18n.t("contests.nav.subtitle.#{key}", title: contest.title, date: I18n.l(date.to_date, format: :long))
    end
  end
end
