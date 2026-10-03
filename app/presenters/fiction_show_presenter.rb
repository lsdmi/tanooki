# frozen_string_literal: true

# View-model for fiction#show: chapters, comments, reading progress, and sidebar data.
class FictionShowPresenter
  def initialize(fiction, current_user, params = {})
    @fiction = fiction
    @current_user = current_user
    @params = params
  end

  def comments
    @comments ||= @fiction.comments.parents.includes(
      { user: { avatar: :image_attachment } },
      replies: { user: { avatar: :image_attachment } }
    ).order(created_at: :desc)
  end

  def new_comment
    @new_comment ||= Comment.new
  end

  def reading_progress
    @reading_progress ||= find_or_fix_reading_progress
  end

  def continue_reading
    return unless reading_progress

    @continue_reading ||= Library::ContinueReadingPresenter.new(reading_progress, viewer: @current_user)
  end

  def reading_started? = continue_reading&.started? || false

  # Guests always get About: their page is one cached variant, and a URL hash picks another tab on the client.
  def default_tab = @current_user && reading_started? ? :chapters : :about

  def bookmark_stats
    Rails.cache.fetch("fiction-#{@fiction.slug}-stats", expires_in: 4.hours) do
      Fictions::ReadingStatusCounts.new(fiction: @fiction).call
    end
  end

  def ranks
    @ranks ||= Rails.cache.fetch("fiction-#{@fiction.slug}-ranks", expires_in: 1.hour) do
      Fictions::Ranker.new(fiction: @fiction).call.sort_by { |_genre, rank| rank }.to_h
    end
  end

  def related_fictions
    @related_fictions ||= @fiction.related_fictions.includes(:fiction_ratings).limit(8).to_a
  end

  def order = @params[:order] || :desc

  def sorted_chapters_locals
    {
      fiction: @fiction,
      order:
    }
  end

  def bookmarks_total_count
    bookmark_stats.sum
  end

  def first_chapter
    @first_chapter ||= ordered_chapters.first
  end

  private

  def chapters_list_scope
    @chapters_list_scope ||= Library::ChapterCatalog.chapters_scope_for_list(@fiction, @current_user)
  end

  def ordered_chapters
    @ordered_chapters ||= chapters_list_scope.order(Library::ChapterCatalog.order_clause)
  end

  def ordered_chapters_desc
    @ordered_chapters_desc ||= chapters_list_scope.order(Library::ChapterCatalog.order_clause_desc)
  end

  def find_or_fix_reading_progress
    progress = ReadingProgress.find_by(fiction_id: @fiction.id, user_id: @current_user&.id)
    return nil unless progress

    # Check if the chapter still exists
    return progress if progress.chapter

    # Handle missing chapter
    handle_missing_chapter(progress)
  end

  def handle_missing_chapter(progress)
    return clear_reading_progress(progress) if chapters_list_scope.none?

    advance_reading_progress_to_last_available(progress)
  end

  def clear_reading_progress(progress)
    progress.destroy
    nil
  end

  def advance_reading_progress_to_last_available(progress)
    last = last_chapter
    return clear_reading_progress(progress) unless last

    progress.update(chapter: last)
    progress.reload
  end

  def last_chapter
    @last_chapter ||= ordered_chapters_desc.first
  end
end
