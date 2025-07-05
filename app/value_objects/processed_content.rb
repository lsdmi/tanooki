# frozen_string_literal: true

# Value object for processed content
class ProcessedContent
  attr_reader :title, :description, :cover_url, :tag_ids

  def initialize(title:, description:, cover_url:, tag_ids:)
    @title = title
    @description = description
    @cover_url = cover_url
    @tag_ids = tag_ids
  end
end
