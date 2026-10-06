# frozen_string_literal: true

module Chapters
  # Strict allowlist for chapter bodies that do not come from the composer (Markdown conversion, later the API).
  # The render-time Action Text sanitizer is permissive (iframes, styles) because it trusts the composer; this one
  # runs on write. Links must be http(s), images must be chapter image storage, spans must be composer notes.
  # Returns the clean HTML plus what was removed (Ukrainian, for the user).
  class ApiContentSanitizer
    Result = Data.define(:html, :changes)

    TAGS = %w[p br strong b em i u s blockquote h2 h3 h4 hr ul ol li table thead tbody tr th td a img span].freeze
    ATTRIBUTES = {
      'a' => %w[href], 'img' => %w[src alt], 'span' => %w[class data-note data-note-id],
      'th' => %w[colspan rowspan], 'td' => %w[colspan rowspan]
    }.freeze
    RENAMES = { 'h1' => 'h2', 'h5' => 'h4', 'h6' => 'h4', 'del' => 's', 'strike' => 's' }.freeze
    # Removed with everything inside; any other unknown tag is unwrapped and its text kept.
    DROP_WITH_CONTENT = %w[script style iframe frame frameset object embed applet noscript template svg math form
                           input button select textarea option canvas audio video source track link meta base
                           head title].freeze
    LINK_SCHEMES = %w[http https].freeze

    def self.call(html)
      new.call(html)
    end

    def call(html)
      @changes = []
      fragment = Loofah.html5_fragment(ReaderContentHtml.normalize(html.to_s))
      fragment.scrub!(Loofah::Scrubber.new(direction: :bottom_up) { |node| scrub(node) })
      Result.new(html: fragment.to_html.strip, changes: @changes.uniq)
    end

    private

    def scrub(node)
      return if node.text?
      return node.remove unless node.element?

      node.name = RENAMES.fetch(node.name, node.name)
      return drop(node, :tag, tag: node.name) if DROP_WITH_CONTENT.include?(node.name)
      return unwrap(node) unless TAGS.include?(node.name)

      strip_attributes(node)
      check_element(node)
    end

    def check_element(node)
      case node.name
      when 'a' then check_link(node)
      when 'img' then check_image(node)
      when 'span' then check_span(node)
      end
    end

    def check_link(node)
      unwrap(node, :link, url: node['href'].to_s.strip.first(80)) unless safe_link?(node['href'])
    end

    def check_image(node)
      drop(node, :image, url: image_label(node['src'])) unless storage_image?(node['src'])
    end

    def check_span(node)
      note_span?(node) ? node['class'] = 'note-reference' : unwrap(node)
    end

    def strip_attributes(node)
      allowed = ATTRIBUTES.fetch(node.name, [])
      node.attribute_nodes.each do |attribute|
        next if allowed.include?(attribute.name)

        note(:attribute, name: attribute.name) if attribute.name == 'style' || attribute.name.start_with?('on')
        attribute.remove
      end
    end

    def safe_link?(href)
      LINK_SCHEMES.include?(URI.parse(href.to_s.strip).scheme&.downcase)
    rescue URI::InvalidURIError
      false
    end

    def storage_image?(src)
      src = src.to_s.strip
      return false if src.blank?
      return true if Images.cdn_key(src)

      src.start_with?('/rails/active_storage/blobs/') && src.match?(Images::REDIRECT_PATH)
    end

    def image_label(src)
      src.to_s.start_with?('data:') ? I18n.t('chapters.content_sanitizer.inline_image') : src.to_s.first(80)
    end

    def note_span?(node)
      node['class'].to_s.split.include?('note-reference') && node['data-note'].present?
    end

    def unwrap(node, change = nil, **details)
      note(change, **details) if change
      node.children.each { |child| node.add_previous_sibling(child) }
      node.remove
    end

    def drop(node, change, **details)
      note(change, **details)
      node.remove
    end

    def note(change, **details)
      @changes << I18n.t("chapters.content_sanitizer.removed.#{change}", **details)
    end
  end
end
