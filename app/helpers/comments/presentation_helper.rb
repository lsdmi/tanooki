# frozen_string_literal: true

module Comments
  # View entry point for comment UI helpers; delegates to Comments::Presentation.
  module PresentationHelper
    delegate :application_record_child, to: Comments::Presentation
    delegate :comment_url, :commentable_title, to: :comments_presentation

    def no_comments_prompt
      Comments::Presentation.empty_state_for(params[:controller])
    end

    def show_comment_status?
      current_user.latest_read_comment_id != latest_comments.first&.id
    end

    private

    def comments_presentation
      @comments_presentation ||= Comments::Presentation.new
    end
  end
end
