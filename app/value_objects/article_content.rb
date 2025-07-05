# frozen_string_literal: true

# Value object for article content
class ArticleContent
  attr_reader :text, :video_url, :cover_url

  def initialize(text: nil, video_url: nil, cover_url: nil)
    @text = text
    @video_url = video_url
    @cover_url = cover_url
  end
end
