# frozen_string_literal: true

module Library
  # View helpers delegating to {ChapterCatalog}.
  module ChapterCatalogHelper
    delegate :ordered_user_chapters_desc, :fiction_has_listable_chapters?, to: ChapterCatalog

    def ordered_chapters(fiction, viewer: nil)
      ChapterCatalog.ordered_chapters(fiction, viewer: viewer)
    end

    def ordered_chapters_desc(fiction, viewer: nil)
      ChapterCatalog.ordered_chapters_desc(fiction, viewer: viewer)
    end

    def chapters_size(fiction, viewer: nil)
      ChapterCatalog.chapters_size(fiction, viewer: viewer)
    end
  end
end
