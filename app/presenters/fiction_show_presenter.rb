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
    @reading_progress ||= ReadingProgress.find_by(fiction_id: @fiction.id, user_id: @current_user&.id)
  end

  def reading_status
    return :not_started unless reading_progress
    return :not_started unless last_chapter

    return :finished  if finished_reading?
    return :dropped   if dropped_reading?
    return :postponed if postponed_reading?

    :active
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

  def last_chapter
    @last_chapter ||= ordered_chapters_desc(@fiction).first
  end

  def finished_reading?
    reading_progress.chapter_id == last_chapter.id
  end

  def dropped_reading?
    reading_progress.updated_at < last_chapter.created_at - 2.months
  end

  def postponed_reading?
    reading_progress.updated_at < last_chapter.created_at - 1.month
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
