# frozen_string_literal: true

class TrackingService
  def initialize(object, cookies)
    @object = object
    @cookies = cookies
  end

  def call
    return if viewed_content.include?(@object.slug)

    @object.increment!(:views)
    add_to_viewed_content(@object.slug)
  end

  private

  def viewed_content
    @viewed_content ||= begin
      content = @cookies[:viewed]
      content.is_a?(String) ? JSON.parse(content) : (content || [])
    rescue JSON::ParserError
      []
    end
  end

  def add_to_viewed_content(slug)
    new_content = viewed_content + [slug]
    new_content = new_content.last(10)
    @cookies[:viewed] = new_content.to_json
  end
end
