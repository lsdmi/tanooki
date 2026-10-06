# frozen_string_literal: true

module Chapters
  # Turbo Streams for a read change on the fiction page Chapters tab (single toggle or «Позначити прочитаними 1–85»).
  # Besides the changed rows it recounts the group headers, the tab header and the hero, and moves the continue row
  # and chip when the target changed. The including controller defines `fiction` and runs
  # `remember_continue_target` before the change.
  module FictionListReadStreams
    private

    def remember_continue_target
      @continue_before = list_progress.continue_chapter_id
    end

    def fiction_list_streams(rows)
      progress = list_progress
      continue_id = progress.continue_chapter_id
      moved = continue_id != @continue_before
      rows = with_continue_rows(rows, continue_id) if moved
      streams = list_row_streams(rows, progress) + counter_streams(progress)
      streams << continue_chip_stream(rows.find { |chapter| chapter.id == continue_id }) if moved
      streams << hero_actions_stream
    end

    def with_continue_rows(rows, continue_id)
      rows + list_scope.where(id: [@continue_before, continue_id].compact).where.not(id: rows.map(&:id))
    end

    def list_row_streams(rows, progress)
      rows.map do |chapter|
        turbo_stream.replace(helpers.dom_id(chapter, :chapter_list),
                             partial: 'fictions/chapter_item',
                             locals: { chapter:, reader_drawer: false, drawer_progress: progress })
      end
    end

    # Every group, not only the toggled one: the first read switches all headers from counts to progress.
    def counter_streams(progress)
      listed = Library::ChapterCatalog.listed_chapters(fiction, viewer: current_user)
      groups = Chapters::ListSectionIndex.new(listed, order: :asc).call.map do |section|
        locals = { section:, drawer_progress: progress }
        turbo_stream.replace("chapter_group_progress_#{section[:section_key]}",
                             partial: 'fictions/chapter_group_progress', locals:)
      end
      total = Library::ChapterCatalog.chapters_size(fiction, viewer: current_user)
      groups << turbo_stream.replace('chapter_list_progress', partial: 'fictions/chapter_list_progress',
                                                              locals: { listed:, total:, list_progress: progress })
    end

    def continue_chip_stream(continue_chapter)
      turbo_stream.update('chapter_continue_chip', partial: 'fictions/continue_chip', locals: { continue_chapter: })
    end

    def hero_actions_stream
      presenter = FictionShowPresenter.new(fiction, current_user)
      turbo_stream.replace(Fictions::HeroActionsComponent::DOM_ID,
                           Fictions::HeroActionsComponent.new(fiction:, presenter:, user: current_user))
    end

    # Only chapters the list can show this viewer: no drafts, no scheduled chapters of other teams.
    def list_scope
      Library::ChapterCatalog.chapters_scope_for_list(fiction, current_user)
    end

    def list_progress
      Reading::ChapterDrawerProgress.build(fiction:, viewer: current_user)
    end
  end
end
