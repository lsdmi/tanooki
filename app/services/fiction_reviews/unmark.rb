# frozen_string_literal: true

module FictionReviews
  # Takes the review mark off a comment. The comment stays a normal comment. Its author or an admin may do it.
  class Unmark
    Result = Data.define(:ok, :error)

    def self.call(...) = new(...).call

    def initialize(comment:, user:)
      @comment = comment
      @user = user
    end

    def call
      return failure(:guest) unless @user
      return failure(:not_allowed) unless @user.admin? || @comment.user_id == @user.id

      review = @comment.fiction_review
      return failure(:not_marked) unless review

      review.destroy!
      Result.new(ok: true, error: nil)
    end

    private

    def failure(error)
      Result.new(ok: false, error:)
    end
  end
end
