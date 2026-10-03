# frozen_string_literal: true

module Comments
  # View entry point for comment UI helpers; delegates to Comments::Presentation.
  module PresentationHelper
    COMMENT_TEXT_CLASS = 'whitespace-pre-line break-words text-sm/5 text-fg-secondary'
    # Replies shown under a comment before «Показати ще N відповіді».
    REPLIES_PREVIEW = 2

    delegate :application_record_child, to: Comments::Presentation
    delegate :comment_url, :commentable_title, to: :comments_presentation

    def no_comments_prompt
      Comments::Presentation.empty_state_for(params[:controller])
    end

    def show_comment_status?
      return false unless current_user

      current_user.latest_read_comment_id != latest_comments.first&.id
    end

    # «· Команда» next to the name: the author is in one of the fiction's teams.
    def comment_by_fiction_team?(comment, fiction)
      return false unless fiction.is_a?(Fiction)

      Library::RequestMemo.remember(:fiction_team_user_ids, fiction.id) do
        ScanlatorUser.where(scanlator_id: fiction.scanlators.map(&:id)).distinct.pluck(:user_id).to_set
      end.include?(comment.user_id)
    end

    def comment_login_path(commentable)
      return new_user_session_path unless commentable.is_a?(Fiction)

      new_user_session_path(return_to: fiction_path(commentable, anchor: 'comments'))
    end

    private

    def comments_presentation
      @comments_presentation ||= Comments::Presentation.new
    end
  end
end
