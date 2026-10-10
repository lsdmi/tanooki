# frozen_string_literal: true

module Api
  class Limits
    # Hourly burst and the five-hour session cap for edits of live chapters.
    class PublishedEdits
      def self.charge!(user)
        new(user).charge!
      end

      def self.hour_period(time = Time.current)
        time.strftime('%Y%m%d%H')
      end

      def self.span_period(time = Time.current)
        (time.to_i / Limits::EDIT_SPAN.to_i).to_s
      end

      def initialize(user)
        @user = user
      end

      def charge!
        charge_hour
        charge_span
      end

      private

      def charge_hour
        count = bump(:published_edit_hour, self.class.hour_period, 2.hours)
        return if count <= Limits::PUBLISHED_EDITS_PER_HOUR

        raise cap('на годину', Limits::PUBLISHED_EDITS_PER_HOUR, hour_wait)
      end

      def charge_span
        count = bump(:published_edit_span, self.class.span_period, 6.hours)
        return if count <= Limits::PUBLISHED_EDITS_PER_SPAN

        raise cap('на 5 годин', Limits::PUBLISHED_EDITS_PER_SPAN, span_wait)
      end

      def bump(kind, period, expires_in)
        Rails.cache.increment(Limits.counter_key(kind, user, period), 1, expires_in:)
      end

      def cap(window, limit, seconds)
        Error.new('published_edit_cap', :too_many_requests, { limit:, window:, wait: wait_label(seconds) })
      end

      def hour_wait(time = Time.current)
        [(time.end_of_hour - time).ceil, 1].max
      end

      def span_wait(time = Time.current)
        left = Limits::EDIT_SPAN.to_i - (time.to_i % Limits::EDIT_SPAN.to_i)
        left.zero? ? Limits::EDIT_SPAN.to_i : left
      end

      def wait_label(seconds)
        minutes = [(seconds.to_i / 60.0).ceil, 1].max
        hours = minutes / 60
        rest = minutes % 60
        return "#{rest} хв" if hours.zero?

        rest.zero? ? "#{hours} год" : "#{hours} год #{rest} хв"
      end

      attr_reader :user
    end
  end
end
