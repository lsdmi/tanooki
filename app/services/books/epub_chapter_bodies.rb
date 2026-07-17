# frozen_string_literal: true

module Books
  # Loads chapter HTML for EPUB export without Action Text rendering overhead.
  module EpubChapterBodies
    def self.raw_html(chapter)
      ActionText::RichText.where(record_type: chapter.class.name, record_id: chapter.id, name: 'content')
                          .pick(:body)
                          .to_s
    end
  end
end
