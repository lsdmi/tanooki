# frozen_string_literal: true

class FictionShowPresenter
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
      translator: translator.join('-'),
      reading_progress:,
      before_next_chapter:,
      order:
    }
  end

  private

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
