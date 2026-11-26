# frozen_string_literal: true

module Fictions
  module Reviews
    # The review control next to «Відповісти» under a reader's own top-level fiction comment: mark it, take the mark
    # off, or say why it cannot be marked yet. The rules are the service's (Eligibility); this only picks the copy.
    # An admin may also take the mark off someone else's review (Unmark allows it), so the control stays for them.
    class ActionComponent < ViewComponent::Base
      LINK_CLASS = 'inline-flex items-center gap-1 rounded-sm text-xs/5 font-medium text-fg-muted transition-colors ' \
                   'hover:text-fg focus:outline-none focus-visible:ring-2 focus-visible:ring-line-strong'
      HINT_CLASS = 'text-xs/5 text-fg-muted'

      # list_state: the order and filter of the list the comment sits in, so the response can redraw the filter.
      def initialize(comment:, fiction:, user:, list_state: nil)
        super()
        @comment = comment
        @fiction = fiction
        @user = user
        @list_state = list_state
      end

      def render?
        return false unless user && fiction.is_a?(Fiction) && comment.parent_id.nil?

        marked? ? own_or_admin? : own?
      end

      private

      attr_reader :comment, :fiction, :user, :list_state

      def review_path = comment_review_path(comment, **review_query)

      def review_query
        { order: list_state&.dig(:order)&.to_s, filter: list_state&.dig(:reviews_only) ? 'reviews' : nil }.compact_blank
      end

      def marked? = comment.fiction_review.present?

      def own? = comment.user_id == user.id

      def own_or_admin? = own? || user.admin?

      # Mirrors the order Mark checks: rating first, then the one-review rule, then the length.
      def state
        return :unmark if marked?

        reason = FictionReviews::Eligibility.call(user:, comment:).reason
        return reason_state(reason) if reason
        return :too_short if comment.content.to_s.length < FictionReview::MIN_LENGTH

        :mark
      end

      def reason_state(reason)
        { no_rating: :rate_first, already_has_review: :already_reviewed }[reason]
      end

      def link_class = LINK_CLASS

      def hint_class = HINT_CLASS
    end
  end
end
