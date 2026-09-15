# frozen_string_literal: true

# Chapter reading, comments, and authenticated create/update for translation teams.
class ChaptersController < ApplicationController
  include Chapters::CreationAuthorization
  include Chapters::ShowTracking
  include ChaptersViewHelpers
  include ChapterPublicAccess
  include ChapterScheduleParams
  include FictionQuery

  before_action :authenticate_user!, except: %i[show]
  before_action :set_chapter, only: %i[show edit update record_progress]
  before_action :set_list_page, only: %i[edit update]
  before_action :set_fiction_for_chapter_create, only: %i[new create]
  before_action :authorize_chapter_creation, only: %i[new create]
  before_action :redirect_if_chapter_not_yet_public, only: %i[show record_progress]
  before_action :track_visit, :track_reading_progress, only: :show
  before_action :verify_permissions, except: %i[new create show record_progress]

  def show
    @comments = load_chapter_comments
    @comment = Comment.new
    @previous_chapter = Library::ChapterNavigation.previous_chapter(
      @chapter.fiction, @chapter, viewer: current_user
    )
    @next_chapter = Library::ChapterNavigation.following_chapter(
      @chapter.fiction, @chapter, viewer: current_user
    )
    @fiction_sidebar_presenter = FictionShowPresenter.new(@chapter.fiction, current_user, params)
    assign_reader_ad_drawer_session
  end

  # Used when Turbo shows a prefetched chapter: show skipped progress on prefetch, this records on real view.
  def record_progress
    return head(:no_content) if @chapter.draft?

    changed = Reading::RecordProgress.new(chapter: @chapter, user: current_user).call
    head(changed ? :ok : :no_content)
  end

  def new
    @chapter = Chapter.new
  end

  def edit; end

  def create
    @chapter = Chapter.new(chapter_params)
    @chapter.user = current_user
    return render_new_with_schedule_error if published_at_schedule_invalid?

    persist_chapter(failure_template: 'chapters/new')
  end

  def update
    return render_edit_with_schedule_error if published_at_schedule_invalid?

    persist_chapter(failure_template: 'chapters/edit')
  end

  private

  def persist_chapter(failure_template:)
    saved = Chapters::Persist.call(
      chapter: @chapter,
      attributes: chapter_params,
      intent: params[:intent],
      user: current_user
    )
    return render failure_template, status: :unprocessable_content unless saved

    redirect_after_persist
  end

  def redirect_after_persist
    if @chapter.draft?
      redirect_to edit_chapter_path(@chapter, page: @list_page), notice: chapter_draft_notice
    elsif @chapter.previously_new_record?
      redirect_to reading_path(@chapter.fiction), notice: t('chapters.notices.create_success')
    else
      redirect_to reading_path(@chapter.fiction, page: @list_page), notice: t('chapters.notices.update_success')
    end
  end

  # Editing starts from a paginated chapter list, so its page travels through the
  # form and back into the redirect. Page 1 stays implicit to keep URLs clean.
  def set_list_page
    page = params[:page].to_i
    @list_page = page if page > 1
  end

  def load_chapter_comments
    @chapter.comments.parents.includes(
      user: { avatar: :image_attachment },
      replies: { user: { avatar: :image_attachment } }
    ).order(created_at: :desc)
  end

  def set_chapter
    @chapter = @commentable = Chapter.friendly.find(params.expect(:id))
  end

  def chapter_params
    permitted = params.expect(
      chapter: [:content, :fiction_id, :number, :title, :volume_number,
                :published_at_date, :published_at_time,
                { scanlator_ids: [] }]
    )
    merge_published_at_from_schedule_fields(permitted)
  end

  def chapter_draft_notice
    if @chapter.status_before_last_save == 'published'
      t('chapters.notices.unpublished')
    else
      t('chapters.notices.draft_saved')
    end
  end

  def verify_permissions
    redirect_to root_path unless current_user.manages_chapter?(@chapter)
  end
end
