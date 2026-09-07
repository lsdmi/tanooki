# frozen_string_literal: true

# Syncs parent fiction status after chapter create/update.
module ChapterFictionStatusUpdate
  extend ActiveSupport::Concern

  private

  def update_fiction_status
    fiction = @chapter.fiction.reload
    Catalog::RefreshChapterStats.call(fiction)
    new_status = Fictions::DeriveStatusFromChapters.new(fiction.reload).call
    fiction.status = new_status
    fiction.save(validate: false)
  end
end
