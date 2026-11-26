# frozen_string_literal: true

# View-model for fiction#show: chapters, comments, reading progress, and sidebar data.
class FictionShowPresenter
  def initialize(fiction, current_user, params = {}, content_filter: ContentFilters::Preference.open)
    @fiction = fiction
    @current_user = current_user
    @params = params
    @content_filter = content_filter
  end

  COMMENTS_PAGE_SIZE = 10

  delegate :comments, :more_comments?, :comments_order, :comments_page, :new_comment, :reviews_only?,
           :review_stats, :list_state, to: :comments_thread

  def reading_progress
    @reading_progress ||= find_or_build_reading_progress
  end

  def continue_reading
    return unless reading_progress

    @continue_reading ||= Library::ContinueReadingPresenter.new(reading_progress, viewer: @current_user)
  end

  def reading_started? = continue_reading&.started? || false

  # The chapter the hero «Продовжити» opens; the chapter list opens its group. Nil for guests, before the first
  # chapter is opened and once everything is read.
  def list_continue_chapter
    return unless @current_user && reading_started? && !continue_reading.all_read?

    continue_reading.continue_chapter
  end

  # Guests always get About: their page is one cached variant, and a URL hash picks another tab on the client.
  # So does a licensed work with no chapter left to list.
  def default_tab
    @current_user && reading_started? && @fiction.license_chapters_state != :removed ? :chapters : :about
  end

  def bookmark_stats
    Rails.cache.fetch("fiction-#{@fiction.slug}-stats", expires_in: 4.hours) do
      Fictions::ReadingStatusCounts.new(fiction: @fiction).call
    end
  end

  def ranks
    @ranks ||= Rails.cache.fetch(ranks_cache_key, expires_in: 1.hour) do
      Fictions::Ranker.new(fiction: @fiction).call.sort_by { |_genre, rank| rank }.to_h
    end
  end

  # Warm-cache only — no Ranker. Used on show to inline honors without CLS or cold TTFB hit.
  def ranks_if_cached
    Rails.cache.read(ranks_cache_key)
  end

  def similar_fictions = @similar_fictions ||= similar_finder.fictions

  def similar_hidden_count = similar_fictions && similar_finder.hidden_count

  def curated_bookshelves
    @curated_bookshelves ||= Fictions::CuratedBookshelves.call(**curated_shelf_args)
  end

  def order = @params[:order] || :desc

  def sorted_chapters_locals = { fiction: @fiction, order:, filter: @params[:filter], team: @params[:team] }

  def bookmarks_total_count = bookmark_stats.sum

  def first_chapter = @first_chapter ||= ordered_chapters.first

  private

  def comments_thread = @comments_thread ||= FictionShow::CommentsThread.new(@fiction, @params)

  def similar_finder = @similar_finder ||= Fictions::SimilarFictions.new(@fiction, filter: @content_filter)

  def curated_shelf_args = { fiction: @fiction, viewer: @current_user, filter: @content_filter }

  def ranks_cache_key = "fiction-#{@fiction.slug}-ranks"

  def chapters_list_scope
    @chapters_list_scope ||= Library::ChapterCatalog.chapters_scope_for_list(@fiction, @current_user)
  end

  def ordered_chapters
    @ordered_chapters ||= chapters_list_scope.order(Library::ChapterCatalog.order_clause)
  end

  def ordered_chapters_desc
    @ordered_chapters_desc ||= chapters_list_scope.order(Library::ChapterCatalog.order_clause_desc)
  end

  def find_or_build_reading_progress
    progress = ReadingProgress.find_by(fiction_id: @fiction.id, user_id: @current_user&.id)
    return nil unless progress
    return progress if progress.chapter

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
