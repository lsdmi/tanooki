# frozen_string_literal: true

module Api
  class Limits
    # Current counters for one user. Reads the cache and does not charge a limit.
    class Usage
      def self.snapshot(user)
        new(user).to_h
      end

      def self.accounts
        User.where(id: account_ids).order(:name).map { |user| [user, snapshot(user)] }
      end

      def self.account_ids
        token_ids = ApiToken.active.distinct.pluck(:user_id)
        oauth_ids = Doorkeeper::AccessToken.where(revoked_at: nil).distinct.pluck(:resource_owner_id)
        (token_ids + oauth_ids).compact.uniq
      end
      private_class_method :account_ids

      def initialize(user)
        @user = user
      end

      def to_h
        {
          published_edits_this_hour: window(:published_edit_hour, PublishedEdits.hour_period, Limits::PUBLISHED_EDITS_PER_HOUR),
          published_edits_per_5_hours: window(:published_edit_span, PublishedEdits.span_period, Limits::PUBLISHED_EDITS_PER_SPAN),
          chapters_created_today: window(:create, Date.current, Limits::CREATES_PER_DAY),
          unpublishes_today: window(:unpublish, Date.current, Limits::UNPUBLISHES_PER_DAY)
        }
      end

      private

      def window(kind, period, limit)
        used = Rails.cache.read(Limits.counter_key(kind, user, period)).to_i
        { used:, limit:, remaining: [limit - used, 0].max }
      end

      attr_reader :user
    end
  end
end
