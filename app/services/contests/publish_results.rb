# frozen_string_literal: true

module Contests
  # Sets results_published_at and busts winner fiction caches.
  class PublishResults
    class Error < StandardError; end

    def self.call(**) = new(**).tap(&:call)

    def initialize(contest:, actor:)
      @contest = contest
      @actor = actor
    end

    def call
      ensure_publishable!
      Contest.transaction do
        contest.update!(results_published_at: Time.current)
        touch_winner_fictions
      end
      self
    end

    private

    attr_reader :contest, :actor

    def ensure_publishable!
      raise Error, I18n.t('contests.authorization.forbidden') unless actor&.admin?
      raise Error, I18n.t('admin.contests.results.already_published') if contest.results_published?
      raise Error, I18n.t('admin.contests.results.cancelled') if contest.cancelled?
    end

    def touch_winner_fictions
      contest.awards.includes(contest_entry: :fiction).find_each do |award|
        fiction = award.contest_entry.fiction
        next if fiction.blank?

        fiction.update!(updated_at: Time.current)
      end
    end
  end
end
