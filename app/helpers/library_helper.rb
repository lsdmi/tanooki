# frozen_string_literal: true

module LibraryHelper
  include LibraryChapterCatalogHelper
  include LibraryChapterNavigationHelper

  STATUSES = {
    'Читаю' => :active,
    'Прочитано' => :finished,
    'Відкладено' => :postponed,
    'Покинуто' => :dropped
  }.freeze

  def status_filters
    STATUSES
  end

  def status_label_for(status)
    status_filters.key(status)
  end
end
