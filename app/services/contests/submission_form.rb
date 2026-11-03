# frozen_string_literal: true

module Contests
  # One-screen contest create: author page → fiction → accepted entry (single transaction).
  class SubmissionForm
    include ActiveModel::Model

    DEFAULT_PLACEHOLDER_COVER = Rails.root.join('app/assets/images/novel.webp').freeze

    attr_accessor :user, :contest, :params
    attr_reader :fiction, :entry, :scanlator, :eligibility

    validates :title, presence: true, length: { in: 3..100 }
    validates :description, presence: true, length: { in: 25..1000 }
    validates :ai_usage, inclusion: { in: ContestEntry::AI_USAGES }
    validate :rules_must_be_accepted
    validate :user_may_submit

    def save
      self.params = (params || {}).with_indifferent_access
      @eligibility = Eligibility.new(user:, contest:)
      return false unless valid?

      Contest.transaction { persist! }
      true
    rescue ActiveRecord::RecordInvalid, SubmitEntry::Error => e
      errors.add(:base, e.message)
      false
    end

    def existing_fiction
      return if user.blank?

      user.fictions
          .where(created_at: contest.submissions_open_at..)
          .where.not(id: contest.entries.select(:fiction_id))
          .order(created_at: :desc)
          .first
    end

    private

    def persist!
      @scanlator = CreateAuthorPage.call(user)
      @fiction = build_fiction
      attach_cover_if_needed
      save_fiction!
      @entry = SubmitEntry.call(user:, contest:, fiction:, scanlator:, **entry_answers).entry
    end

    def save_fiction!
      scanlator_ids = [scanlator.id.to_s]
      fiction.scanlator_ids = scanlator_ids
      fiction.genre_ids = auto_genre_ids
      fiction.save!
      Fictions::SyncAssociations.new(fiction, genre_ids: auto_genre_ids, scanlator_ids:, user:).call
    end

    def entry_answers
      %i[ai_usage ai_note rules_accepted].index_with { |key| params[key] }
    end

    def build_fiction
      Fiction.new(
        title: params[:title],
        description: params[:description],
        author: user.name,
        origin: default_origin,
        content_rating: resolved_content_rating,
        cover: params[:cover]
      )
    end

    def attach_cover_if_needed
      return if fiction.cover.attached?

      if contest.entry_placeholder_cover.attached?
        fiction.cover.attach(contest.entry_placeholder_cover.blob)
      else
        fiction.cover.attach(
          io: File.open(DEFAULT_PLACEHOLDER_COVER),
          filename: 'novel.webp',
          content_type: 'image/webp'
        )
      end
    end

    def auto_genre_ids
      return [] if contest.required_genre_id.blank?

      [contest.required_genre_id.to_s]
    end

    def default_origin
      contest.translation? ? :nknown : :ukrainian
    end

    def resolved_content_rating
      raw = params[:content_rating].presence
      return :everyone if raw.blank?
      return raw if Fiction.content_ratings.key?(raw.to_s)

      Fiction.content_ratings.key(raw.to_i) || :everyone
    end

    def title = params&.dig(:title)
    def description = params&.dig(:description)
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
