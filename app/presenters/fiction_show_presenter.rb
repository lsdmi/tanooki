# frozen_string_literal: true

class FictionShowPresenter
  include LibraryHelper

  attr_reader :translator

  def initialize(fiction, current_user, params)
    @fiction = fiction
    @current_user = current_user
    @params = params
    set_translator
  end

  def comments
    @comments ||= @fiction.comments.parents.includes(:replies, :user).order(created_at: :desc)
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
    Rails.cache.fetch("fiction-#{@fiction.slug}-ranks", expires_in: 24.hours) do
      FictionRanker.new(fiction: @fiction).call.sort_by { |_genre, rank| rank }.to_h
    end
  end

  def related_fictions
    @fiction.related_fictions.limit(3)
  end

  def order
    @params[:order] || :desc
  end

  def before_next_chapter
    if duplicate_chapters?
      chapter_manager.before_next_chapter_by_user
    else
      chapter_manager.before_next_chapter
    end
  end

  def sorted_chapters_locals
    {
      fiction: @fiction,
      translator:,
      reading_progress:,
      reading_status:,
      before_next_chapter:,
      order:
    }
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
    # If no chapters exist at all, remove the reading progress
    if @fiction.chapters.empty?
      progress.destroy
      nil
    else
      # If chapters exist but the current one is missing, update to last chapter
      last_chapter = ordered_chapters_desc(@fiction).first
      if last_chapter
        progress.update(chapter: last_chapter)
        progress.reload
      else
        progress.destroy
        nil
      end
    end
  end

  def last_chapter
    @last_chapter ||= ordered_chapters_desc(@fiction).first
  end

  def set_translator
    @translator = @params[:translator] || chapter_manager.translator
    @translator = Array(@translator) unless @translator.is_a?(Array)

    return unless @translator.any? { |t| !@fiction.scanlators.ids.include?(t.to_i) }

    @translator = chapter_manager.translator
  end

  def duplicate_chapters?
    @duplicate_chapters ||= @fiction.chapters.group(:number).having('COUNT(*) > 1').exists?
  end

  def chapter_manager
    @chapter_manager ||= FictionChapterListManager.new(@fiction, reading_progress, @translator)
  end
end
