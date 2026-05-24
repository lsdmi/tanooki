# frozen_string_literal: true

# View-model for fiction#show: chapters, comments, reading progress, and sidebar data.
class FictionShowPresenter
  include LibraryHelper

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

  def reading_status
    return :not_started unless reading_progress
    return :not_started unless last_chapter

    reading_progress.status.to_sym
  end

  def bookmark_stats
    Rails.cache.fetch("fiction-#{@fiction.slug}-stats", expires_in: 4.hours) do
      BookmarksAccounter.new(fiction: @fiction).call
    end
  end

  def ranks
    @ranks ||= Rails.cache.fetch("fiction-#{@fiction.slug}-ranks", expires_in: 1.hour) do
      Fictions::Ranker.new(fiction: @fiction).call.sort_by { |_genre, rank| rank }.to_h
    end
  end

  def related_fictions
    @fiction.related_fictions.limit(3)
  end

  def order
    @params[:order] || :desc
  end

  def sorted_chapters_locals
    {
      fiction: @fiction,
      order:
    }
  end

  def bookmarks_total_count
    bookmark_stats.sum
  end

  def monthly_reads_counts
    @monthly_reads_counts ||= Fictions::IndexVariablesManager.hot_updates_counts
  end

  def monthly_reads_count
    monthly_reads_counts[@fiction.id].to_i
  end

  def monthly_reads_fiction_count
    monthly_reads_counts.size
  end

  def monthly_reads_rank
    return nil if monthly_reads_fiction_count.zero?

    sorted = monthly_reads_counts.values.sort.reverse
    sorted.index(monthly_reads_count)&.+(1) || monthly_reads_fiction_count
  end

  def monthly_reads_stats?
    monthly_reads_fiction_count.positive?
  end

  def support_links?
    @fiction.scanlators.any? { |scanlator| scanlator.bank_url.present? }
  end

  def first_chapter
    @first_chapter ||= ordered_chapters(@fiction, viewer: @current_user).first
  end

  private

  def find_or_fix_reading_progress
    progress = ReadingProgress.find_by(fiction_id: @fiction.id, user_id: @current_user&.id)
    return nil unless progress

    # Check if the chapter still exists
    return progress if progress.chapter

    # Handle missing chapter
    handle_missing_chapter(progress)
  end

  def handle_missing_chapter(progress)
    return clear_reading_progress(progress) if chapters_scope_for_list(@fiction, @current_user).empty?

    advance_reading_progress_to_last_available(progress)
  end

  def clear_reading_progress(progress)
    progress.destroy
    nil
  end

  def advance_reading_progress_to_last_available(progress)
    last = ordered_chapters_desc(@fiction, viewer: @current_user).first
    return clear_reading_progress(progress) unless last

    progress.update(chapter: last)
    progress.reload
  end

  def last_chapter
    @last_chapter ||= ordered_chapters_desc(@fiction, viewer: @current_user).first
  end
end
