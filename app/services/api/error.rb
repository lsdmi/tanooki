# frozen_string_literal: true

module Api
  # A refusal the API can show to the caller. `code` is an `api.errors` key.
  class Error < StandardError
    attr_reader :code, :status, :details

    def initialize(code, status, details = {})
      @code = code.to_s
      @status = status
      @details = details || {}
      super(@code)
    end
  end
end
