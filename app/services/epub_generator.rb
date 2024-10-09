# frozen_string_literal: true

class EpubGenerator
  attr_reader :file_path, :filename

  def initialize(rich_text_ids, volume_title = nil)
    @rich_texts = ActionText::RichText.where(id: Array(rich_text_ids))
    @volume_title = volume_title
    @chapters = @rich_texts.map(&:record)
    @file_path = File.join(Rails.root, 'tmp', "book_#{Time.now.to_i}.epub")
  end

  def generate
    book = build_book
    book.generate_epub(@file_path)
    set_filename
    self
  end

  private

  def build_book
    BookBuilder.new(@chapters, @volume_title).build
  end

  def set_filename
    @filename = if @chapters.size == 1
                  "#{@chapters.first.fiction_title}. #{ContentFormatter.title(@chapters.first)}.epub"
                else
                  "#{@chapters.first.fiction_title} #{@volume_title}.epub"
                end
  end
end
