# frozen_string_literal: true

# Chapter reading, comments, and authenticated create/update for translation teams.
class ChaptersController < ApplicationController
  include ChapterFictionStatusUpdate
  include Chapters::CreationAuthorization
  include ChaptersViewHelpers
  include ChapterScheduleParams
  include FictionQuery

  before_action :authenticate_user!, except: %i[show]
  before_action :set_chapter, only: %i[show edit update]
  before_action :set_fiction_for_chapter_create, only: %i[new create]
  before_action :authorize_chapter_creation, only: %i[new create]
  before_action :redirect_if_chapter_not_yet_public, only: :show
  before_action :track_visit, :track_reading_progress, only: :show
  before_action :verify_permissions, except: %i[new create show]
  before_action :pokemon_appearance, only: [:show]

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

  def new
    @chapter = Chapter.new
  end

  def edit; end

  def create
    @chapter = Chapter.new(chapter_params)
    @chapter.user = current_user
    return render_new_with_schedule_error if published_at_schedule_invalid?

    persist_new_chapter
  end

  def update
    return render_edit_with_schedule_error if published_at_schedule_invalid?

    persist_chapter_update
  end

  private

  def persist_new_chapter
    if @chapter.save
      sync_chapter_scanlator_links
      update_fiction_status
      redirect_to reading_path(@chapter.fiction), notice: t('chapters.notices.create_success')
    else
      render 'chapters/new', status: :unprocessable_content
    end
  end

  def persist_chapter_update
    if @chapter.update(chapter_params)
      sync_chapter_scanlator_links
      update_fiction_status
      redirect_to reading_path(@chapter.fiction), notice: t('chapters.notices.update_success')
    else
      render 'chapters/edit', status: :unprocessable_content
    end
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

  def track_reading_progress
    Reading::RecordProgress.new(chapter: @chapter, user: current_user).call
  end

  # Every-4th-chapter session cadence gates only the auto-opening ad drawer, not top/bottom reader slots.
  def assign_reader_ad_drawer_session
    @reader_ad_drawer_open = false
    return unless chapter_reader_ad_drawer_live?

    state, @reader_ad_drawer_open = Reading::AdDrawerSession.call(
      chapter_id: @chapter.id,
      session_state: session[:reader_ad_drawer]
    )
    session[:reader_ad_drawer] = state
  end

  def verify_permissions
    redirect_to root_path unless current_user.manages_chapter?(@chapter)
  end

  def redirect_if_chapter_not_yet_public
    return unless @chapter.scheduled?
    return if current_user&.admin?
    return if current_user && current_user.scanlators.ids.intersect?(@chapter.scanlators.ids)

    redirect_to fiction_path(@chapter.fiction), alert: t('chapters.alerts.not_yet_public')
  end
end
