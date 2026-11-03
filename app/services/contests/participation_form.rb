# frozen_string_literal: true

module Contests
  # AI + rules-only form for submitting an already-created fiction.
  class ParticipationForm
    include ActiveModel::Model

    attr_accessor :user, :contest, :fiction, :params
    attr_reader :entry, :eligibility

    validates :ai_usage, inclusion: { in: ContestEntry::AI_USAGES }
    validate :rules_must_be_accepted
    validate :user_may_submit

    def save
      self.params = (params || {}).with_indifferent_access
      @eligibility = Eligibility.new(user:, contest:, fiction:)
      return false unless valid?

      @entry = submit_entry.entry
      true
    rescue SubmitEntry::Error => e
      errors.add(:base, e.message)
      false
    end

    private

    def submit_entry
      answers = %i[ai_usage ai_note rules_accepted].index_with { |key| params[key] }
      SubmitEntry.call(user:, contest:, fiction:, **answers)
    end

    def ai_usage = params&.dig(:ai_usage).presence

    def rules_must_be_accepted
      return if ActiveModel::Type::Boolean.new.cast(params&.dig(:rules_accepted))

      errors.add(:rules_accepted, :accepted)
    end

    def user_may_submit
      return if eligibility&.allowed?

      Array(eligibility&.reason_messages).each { |msg| errors.add(:base, msg) }
    end
  end
end
