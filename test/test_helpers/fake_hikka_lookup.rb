# frozen_string_literal: true

# Stands in for Fictions::HikkaLookup in model tests and counts how often Hikka would have been asked.
class FakeHikkaLookup
  class << self
    attr_accessor :result, :calls

    def reset!
      self.calls = 0
      self.result = :found
    end
  end

  def initialize(_slug)
    self.class.calls += 1
  end

  def call
    result = self.class.result
    result.respond_to?(:call) ? result.call : result
  end
end
