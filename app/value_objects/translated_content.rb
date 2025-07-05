# frozen_string_literal: true

# Value object for translated content
class TranslatedContent
  attr_reader :html, :tag_ids

  def initialize(html:, tag_ids:)
    @html = html
    @tag_ids = tag_ids
  end

  def title
    doc = Nokogiri::HTML.fragment(html)
    doc.at('h1')&.text&.strip
  end

  def description
    doc = Nokogiri::HTML.fragment(html)
    doc.children.reject { |n| n.name == 'h1' }.map(&:to_html).join.strip
  end
end
