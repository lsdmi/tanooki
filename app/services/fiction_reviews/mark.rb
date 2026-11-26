# frozen_string_literal: true

module FictionReviews
  # Marks a comment as its author's review. Eligibility checks the business rules first; the model checks the
  # structure. A race that gets past both is stopped by the unique indexes and reported with the same reasons.
  class Mark
    Result = Data.define(:ok, :review, :error)

    # Model validation errors, as [attribute, error], mapped to the reasons Eligibility uses.
    VALIDATION_REASONS = {
      %i[comment not_top_level] => :reply,
      %i[comment not_by_author] => :not_owner,
      %i[comment not_on_fiction] => :not_fiction_comment,
      %i[comment too_short] => :too_short,
      %i[user_id taken] => :already_has_review,
      %i[comment_id taken] => :already_marked
    }.freeze

    def self.call(...) = new(...).call

    def initialize(comment:, user:)
      @comment = comment
      @user = user
    end

    def call
      check = Eligibility.call(user: @user, comment: @comment)
      return failure(check.reason) unless check.ok

      review = FictionReview.new(comment: @comment, user: @user, fiction: check.fiction)
      review.save!
      Result.new(ok: true, review:, error: nil)
    rescue ActiveRecord::RecordInvalid => e
      failure(validation_reason(e.record.errors))
    rescue ActiveRecord::RecordNotUnique => e
      failure(e.message.include?('index_fiction_reviews_on_comment_id') ? :already_marked : :already_has_review)
    end

    private

    def validation_reason(errors)
      errors.details.each do |attribute, details|
        details.each do |detail|
          reason = VALIDATION_REASONS[[attribute, detail[:error]]]
          return reason if reason
        end
      end
      :invalid
    end

    def failure(error)
      Result.new(ok: false, review: nil, error:)
    end
  end
end
