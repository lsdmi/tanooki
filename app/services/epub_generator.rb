# frozen_string_literal: true

class EpubGenerator
  def initialize(rich_text_id)
    @rich_text = ActionText::RichText.find(rich_text_id)
    @chapter = @rich_text.record
    @file_path = File.join(Rails.root, 'tmp', "book_#{Time.now.to_i}.epub")
  end

  def generate
    book = BookBuilder.new(@chapter).build
    book.generate_epub(@file_path)
    @filename = "#{@chapter.fiction_title}. #{ContentFormatter.title(@chapter)}.epub"
  end

  attr_reader :file_path, :filename
end
