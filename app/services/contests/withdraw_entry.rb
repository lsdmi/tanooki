# frozen_string_literal: true

module Contests
  # Author (or soft-delete cascade) withdraws an entry before results are published.
  class WithdrawEntry
    class Error < StandardError; end

    def self.call(**) = new(**).tap(&:call)

    def initialize(entry:, actor: nil, system: false)
      @entry = entry
      @actor = actor
      @system = system
    end

    def call
      raise Error, I18n.t('contests.withdraw.results_published') if entry.contest.results_published?
      raise Error, I18n.t('contests.authorization.forbidden') unless system || can_withdraw?

      entry.update!(status: :withdrawn, status_reason: nil) unless entry.withdrawn?
      self
    end

    private

    attr_reader :entry, :actor, :system

    def can_withdraw?
      Authorization.new(actor, entry).withdraw?
    end
  end
end
