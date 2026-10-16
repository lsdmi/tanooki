# frozen_string_literal: true

module Chapters
  # Lazy turbo-frame endpoints for the immersive reader comments and TOC drawers.
  module LazyDrawers
    extend ActiveSupport::Concern

    LAZY_DRAWER_ACTIONS = %w[comments chapter_list].freeze

    included do
      before_action :set_chapter, if: :chapter_member_action?
      before_action :redirect_if_chapter_not_yet_public, if: :chapter_public_gate_action?
    end

    # Comment trees are not loaded on first HTML paint — only when the drawer opens.
    def comments
      @comments = load_chapter_comments
      @comment = Comment.new
      render layout: false
    end

    # Section index + search JSON load on first TOC open.
    def chapter_list
      @chapter_list_order = params[:order].presence || :desc
      render layout: false
    end

    private

    def lazy_drawer_action?
      LAZY_DRAWER_ACTIONS.include?(action_name)
    end

    def public_chapter_action?
      action_name == 'show' || lazy_drawer_action?
    end

    def chapter_member_action?
      %w[show edit update record_progress].include?(action_name) || lazy_drawer_action?
    end

    def chapter_public_gate_action?
      %w[show record_progress].include?(action_name) || lazy_drawer_action?
    end

    def skip_chapter_permission_check?
      %w[new create show record_progress].include?(action_name) || lazy_drawer_action?
    end

    def load_chapter_comments
      @chapter.comments.parents.includes(
        user: { avatar: :image_attachment },
        replies: { user: { avatar: :image_attachment } }
      ).order(created_at: :desc)
    end
  end
end
