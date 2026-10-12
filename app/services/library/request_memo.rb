# frozen_string_literal: true

module Library
  # Values computed once per request or job (Rails resets CurrentAttributes after each), so one page that asks
  # several helpers for the same fiction's chapter list hits the database once.
  class RequestMemo < ActiveSupport::CurrentAttributes
    attribute :values

    def remember(*key)
      self.values ||= {}
      return values[key] if values.key?(key)

      values[key] = yield
    end

    # For a batch loaded ahead of the callers that would each ask for their own part.
    def store(*key, value)
      self.values ||= {}
      values[key] = value
    end

    # Only what a batch stored: callers that write in the same request must not get a stale value.
    def peek(*key)
      values&.[](key)
    end
  end
end
