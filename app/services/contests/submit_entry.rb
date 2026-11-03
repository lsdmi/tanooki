# frozen_string_literal: true

module Contests
  # Creates or re-opens a contest entry as accepted (moderation is post-hoc).
  class SubmitEntry
    ANSWER_KEYS = %i[ai_usage ai_note rules_accepted].freeze

    class Error < StandardError; end

    attr_reader :entry, :eligibility

    def self.call(**) = new(**).tap(&:call)

    # answers: ai_usage: and rules_accepted: (required), ai_note: (optional).
    def initialize(user:, contest:, fiction:, scanlator: nil, **answers)
      answers.assert_valid_keys(*ANSWER_KEYS)
      @user = user
      @contest = contest
      @fiction = fiction
      @scanlator = scanlator
      @ai_usage = required_answer(answers, :ai_usage)
      @ai_note = answers[:ai_note]
      @rules_accepted = required_answer(answers, :rules_accepted)
      @eligibility = Eligibility.new(user:, contest:, fiction:)
    end

    def call
      raise Error, eligibility.reason_messages.first unless eligibility.allowed?
      raise Error, I18n.t('contests.eligibility.rules_not_accepted') unless rules_accepted?

      @entry = Contest.transaction { persist_entry }
      self
    end

    private

    attr_reader :user, :contest, :fiction, :ai_usage, :ai_note, :rules_accepted, :scanlator

    def required_answer(answers, key)
      answers.fetch(key) { raise ArgumentError, "missing keyword: :#{key}" }
    end

    def rules_accepted?
      ActiveModel::Type::Boolean.new.cast(rules_accepted)
    end

    def persist_entry
      existing = contest.entries.find_by(fiction_id: fiction.id)
      if existing
        reopen!(existing)
      else
        create_entry!
      end
    end

    def entry_attributes
      {
        status: :accepted,
        ai_usage:,
        ai_note:,
        rules_accepted_at: Time.current,
        submitted_at: Time.current,
        submitter: user,
        scanlator: resolved_scanlator
      }
    end

    def reopen!(existing)
      existing.update!(entry_attributes.merge(status_reason: nil, reviewed_at: nil, reviewed_by_id: nil))
      sync_authors!(existing)
      existing
    end

    def create_entry!
      entry = contest.entries.create!(entry_attributes.merge(fiction:))
      sync_authors!(entry)
      entry
    end

    def resolved_scanlator
      scanlator || fiction.scanlators.first
    end

    def sync_authors!(entry)
      author_ids = fiction.users.ids
      author_ids = [user.id] if author_ids.blank?
      entry.entry_authors.where.not(user_id: author_ids).find_each(&:destroy)
      author_ids.each do |user_id|
        entry.entry_authors.find_or_create_by!(user_id:)
      end
    end
  end
end
