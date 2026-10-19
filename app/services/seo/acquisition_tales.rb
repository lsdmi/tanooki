# frozen_string_literal: true

module Seo
  # Idempotent editorial pack for ACQUISITION_AND_HITS_SPIKE §2.3.
  # Data: config/seo/acquisition_tales.yml
  class AcquisitionTales
    CTA_MARKER = 'id="baka-catalog-cta"'
    CTA_SIGNATURE = 'Хочете не лише новини аніме'
    AUTHOR_EMAILS = %w[dima124c41@gmail.com].freeze
    CONFIG_PATH = Rails.root.join('config/seo/acquisition_tales.yml')

    def self.run_drafts!(&) = new(&).run_drafts!

    def self.run_refresh!(&) = new(&).run_refresh!

    def self.run_all!(&)
      instance = new(&)
      instance.run_drafts!
      instance.run_refresh!
    end

    def initialize(&on_message)
      @on_message = on_message || ->(msg) {}
    end

    def run_drafts!
      author = find_author!
      config.fetch('drafts').each { |attrs| upsert_draft!(author, attrs) }
      say 'Drafts ready (status=draft). Attach covers in studio, then publish.'
    end

    def run_refresh!
      config.fetch('refreshes').each { |slug, attrs| append_cta!(slug, cta_html(attrs)) }
      say 'Refresh pass done.'
    end

    private

    def find_author!
      user = AUTHOR_EMAILS.filter_map { |email| User.find_by(email:) }.first || User.order(:id).first
      raise 'No user to own Tales' unless user

      say "Author: ##{user.id} #{user.email}"
      user
    end

    def upsert_draft!(author, attrs)
      slug = attrs.fetch('slug')
      tale = Tale.find_by(slug:) || Tale.new(slug:)
      tale.assign_attributes(title: attrs.fetch('title'), user: author, status: :draft, type: 'Tale')
      tale.description = draft_html(attrs)
      tale.save!
      pin_slug!(tale, slug)
      say "  draft #{tale.reload.slug} (##{tale.id})"
    end

    def pin_slug!(tale, slug)
      return if tale.slug == slug

      tale.slug = slug
      tale.save!
    end

    def append_cta!(slug, html)
      tale = Tale.find_by(slug:)
      return say("  skip missing #{slug}") unless tale

      existing = tale.description.body.to_html
      return say("  skip already refreshed #{slug}") if cta_present?(existing)

      tale.description = "#{existing}#{html}"
      tale.save!
      say "  refreshed #{slug}"
    end

    def cta_present?(html)
      html.include?(CTA_MARKER) || html.include?(CTA_SIGNATURE)
    end

    def draft_html(attrs)
      tag = attrs.fetch('list_style', 'ul')
      items = attrs.fetch('links').map { |path, label| "<li>#{link(path, label)}</li>" }.join
      [
        "<p>#{attrs.fetch('intro')}</p>",
        (attrs['blurb'].present? ? "<p>#{attrs['blurb']}</p>" : nil),
        "<h2>#{attrs.fetch('heading')}</h2>",
        "<#{tag}>#{items}</#{tag}>",
        attrs['footer']
      ].compact.join("\n")
    end

    def cta_html(attrs)
      items = attrs.fetch('links').map { |path, label| "<li>#{link(path, label)}</li>" }.join
      <<~HTML
        <div id="baka-catalog-cta">
        <hr>
        <h2>#{attrs.fetch('title')}</h2>
        <p>#{CTA_SIGNATURE} — а читати історію українською? Ось прямі посилання в каталог Баки:</p>
        <ul>#{items}</ul>
        <p>Увесь каталог: #{link('/fictions', 'читати ранобе українською на Баці')}.</p>
        </div>
      HTML
    end

    def link(path, text) = %(<a href="#{path}">#{text}</a>)

    def say(message) = @on_message.call(message)

    def config = @config ||= YAML.safe_load_file(CONFIG_PATH)
  end
end
