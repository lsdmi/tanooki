# frozen_string_literal: true

class ServiceResult
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
