# frozen_string_literal: true

module Contests
  # Admin moderation of a contest entry (post-hoc review, reject, disqualify).
  class ReviewEntry
    class Error < StandardError; end

    def self.call(**) = new(**).tap(&:call)

    def initialize(entry:, actor:, action:, reason: nil)
      @entry = entry
      @actor = actor
      @action = action.to_sym
      @reason = reason
    end

    def call
      raise Error, I18n.t('contests.authorization.forbidden') unless Authorization.new(actor, entry).moderate?

      case action
      when :reject then reject
      when :disqualify then disqualify
      else
        raise Error, "Unknown action: #{action}"
      end
      self
    end

    private

    attr_reader :entry, :actor, :action, :reason

    def reject
      raise Error, I18n.t('contests.review.reason_required') if reason.blank?

      entry.update!(
        status: :rejected,
        status_reason: reason,
        reviewed_at: Time.current,
        reviewed_by: actor
      )
    end

    def disqualify
      raise Error, I18n.t('contests.review.reason_required') if reason.blank?

      entry.update!(
        status: :disqualified,
        status_reason: reason,
        reviewed_at: Time.current,
        reviewed_by: actor
      )
    end
  end
end
