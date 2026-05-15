# frozen_string_literal: true

module Outcomes
  # Wraps the result of a service call: success/failure and an optional +data+ payload.
  class OperationOutcome
    attr_reader :success, :data

    def initialize(success:, data: nil)
      @success = success
      @data = data
    end

    def success?
      success
    end

    def failure?
      !success
    end
  end
end
