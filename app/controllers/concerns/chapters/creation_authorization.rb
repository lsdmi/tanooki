# frozen_string_literal: true

module Chapters
  # Authorization and fiction resolution for new/create chapter actions.
  module CreationAuthorization
    extend ActiveSupport::Concern

    private

    def set_fiction_for_chapter_create
      @fiction = fiction_for_chapter_create
    end

    def authorize_chapter_creation
      policy = Chapters::Authorization.new(
        current_user,
        @fiction,
        scanlator_ids: params.dig(:chapter, :scanlator_ids)
      )
      allowed = action_name == 'new' ? policy.new? : policy.create?
      return if allowed

      redirect_to chapter_creation_denied_path
    end

    def chapter_creation_denied_path
      current_user.scanlators.any? ? root_path : new_scanlator_path
    end

    def fiction_for_chapter_create
      if params[:fiction].present?
        Fiction.friendly.find(params[:fiction])
      elsif params.dig(:chapter, :fiction_id).present?
        Fiction.find_by(id: params[:chapter][:fiction_id])
      end
    end

    def sync_chapter_scanlator_links
      Chapters::SyncScanlatorAssociations.new(
        chapter_params[:scanlator_ids], @chapter, user: current_user
      ).call
      @chapter.link_fiction_to_scanlators!
    end
  end
end
