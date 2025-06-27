# frozen_string_literal: true

class BaseContentLoader
  def initialize(service)
    @service = service
  end

  def call
    raise NotImplementedError, "#{self.class} must implement #call"
  end

  private

  attr_reader :service

  delegate :user, :params, to: :service
end
