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
  end
end
