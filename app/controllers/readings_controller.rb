# frozen_string_literal: true

# User reading list: add, remove, and browse tracked fictions.
class ReadingsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_fiction, only: :show
  before_action :set_chapter, only: :destroy
  before_action :authorize_chapter_deletion, only: :destroy

  def show
    redirect_to root_path unless current_user.manages_fiction?(@fiction)

    @pagy, @chapters = pagy(
      Library::ChapterCatalog.ordered_user_chapters_desc(@fiction, current_user),
      limit: 36
    )
  end

  def destroy
    fiction = @chapter.fiction
    team_ids = managed_chapter_scanlator_ids
    @chapter.destroy

    unlink_teams_without_published_chapters(fiction, team_ids)
    Catalog::RefreshChapterStats.call(fiction)

    reload_fiction_chapters
    render turbo_stream: turbo_stream_destroy_success(refresh_list, t('chapters.notices.destroy_success'))
  end

  private

  def set_fiction
    @fiction = Fiction.friendly.find(params.expect(:id))
  end

  def set_chapter
    scope = current_user.admin? ? Chapter : current_user.chapters
    @chapter = scope.friendly.find(params.expect(:id))
  end

  def authorize_chapter_deletion
    return redirect_to root_path unless current_user.manages_chapter?(@chapter)
    return unless @chapter.fiction.license_frozen_for?(current_user)

    render turbo_stream: turbo_stream_alert(t('chapters.alerts.licensed'))
  end

  # Teams the deleter can drop from a shared fiction (admins: every team on the chapter).
  def managed_chapter_scanlator_ids
    ids = @chapter.scanlators.ids
    return ids if current_user.admin?

    ids & current_user.scanlators.ids
  end

  # Drop a team from a shared fiction once it has no published chapters left.
  # Leftover drafts do not keep the public credit; Remover soft-deletes them with the link.
  def unlink_teams_without_published_chapters(fiction, team_ids)
    return if team_ids.empty?
    return unless fiction.scanlators.size > 1

    team_ids.each do |scanlator_id|
      next if published_chapters_remain?(fiction, scanlator_id)

      Fictions::ScanlatorAssociationRemover.new(fiction, Scanlator.find(scanlator_id)).call
    end
  end

  def published_chapters_remain?(fiction, scanlator_id)
    fiction.chapters.not_draft.joins(:chapter_scanlators)
           .exists?(chapter_scanlators: { scanlator_id: })
  end

  def reload_fiction_chapters
    @fiction = @chapter.fiction
    @pagy, @chapters = pagy(
      Library::ChapterCatalog.ordered_user_chapters_desc(@fiction, current_user),
      limit: 36,
      request_path: reading_path(@fiction),
      page: params[:page] || 1
    )
  end

  def refresh_list
    turbo_stream.update(
      'chapters-list',
      partial: 'chapters',
      locals: { fiction: @fiction, pagy: @pagy, chapters: @chapters }
    )
  end
end
