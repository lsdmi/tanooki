# frozen_string_literal: true

module Fictions
  module Reviews
    # Uses the development database: a reader's review, a fiction comment that is not one, and that same review with a
    # spoiler. The spoiler flag is set in memory only, so nothing is saved. The comment header needs a signed-in viewer,
    # so the card shows the badge, the text and the review control, which is what changes between these states.
    class CommentPreview < ViewComponent::Preview
      # @label Відгук: позначка, оцінка, прочитано розділів, зняти позначку
      def review
        render_with_template(template: 'fictions/reviews/comment_preview/card', locals: card_locals(sample_review))
      end

      # @label Коментар: без позначки
      def plain_comment
        render_with_template(template: 'fictions/reviews/comment_preview/card', locals: card_locals(sample_comment))
      end

      # @label Відгук зі спойлером: текст згорнуто
      def spoiler
        comment = sample_review
        comment.spoiler = true
        render_with_template(template: 'fictions/reviews/comment_preview/card', locals: card_locals(comment))
      end

      private

      def card_locals(comment)
        {
          comment:,
          review: comment.fiction_review.present?,
          stats: FictionReviews::ReaderStats.new(fiction: comment.commentable, user_ids: [comment.user_id])
        }
      end

      def sample_review
        comment = FictionReview.includes(comment: %i[user fiction_review]).order(:id).last&.comment
        comment || raise('Add a fiction review to the development database to preview Fictions::Reviews::CommentPreview.')
      end

      def sample_comment
        comment = Comment.where(commentable_type: Fiction.name, parent_id: nil).where.missing(:fiction_review)
                         .includes(:user, :fiction_review).order(:id).last
        comment || raise('Add a top-level fiction comment to the development database to preview it.')
      end
    end
  end
end
