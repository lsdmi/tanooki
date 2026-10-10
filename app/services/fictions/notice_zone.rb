# frozen_string_literal: true

module Fictions
  # Notices above the fiction hero: an optional age notice, then at most one status notice.
  # A licensed work gets the licensed notice whatever its listing state; otherwise the notice
  # follows the listing state (ongoing works get none).
  module NoticeZone
    Notice = Data.define(:kind, :title, :body)

    AGE_KINDS = { 'eighteen' => :adult, 'sixteen' => :teen }.freeze
    STATUS_KINDS = { stale: :dropped, announced: :announced, finished: :finished }.freeze

    module_function

    def for(fiction, age: true)
      age_kind = AGE_KINDS[fiction.content_rating] if age
      [(notice(age_kind) if age_kind), status_notice(fiction)].compact
    end

    def status_notice(fiction)
      return licensed(fiction) if fiction.licensed?

      kind = STATUS_KINDS[fiction.listing_state]
      notice(kind) if kind
    end

    def licensed(fiction)
      Notice.new(
        kind: :licensed,
        title: I18n.t('fictions.notice_zone.licensed.title'),
        body: [license_lead(fiction), license_chapters_note(fiction)].join(' ')
      )
    end

    def license_lead(fiction)
      publisher = fiction.license_publisher
      I18n.t("fictions.notice_zone.licensed.#{publisher ? :lead_with_publisher : :lead}", publisher:)
    end

    def license_chapters_note(fiction)
      preview = fiction.license_preview
      case fiction.license_chapters_state
      when :removed then I18n.t("fictions.notice_zone.licensed.#{fiction.chapters_hidden? ? :removed : :unreleased}")
      when :partial
        key = preview.available_count == 1 ? :preview_one : :preview
        I18n.t("fictions.notice_zone.licensed.#{key}", range: preview.available_range)
      else I18n.t('fictions.notice_zone.licensed.open')
      end
    end

    def notice(kind)
      Notice.new(
        kind:,
        title: I18n.t("fictions.notice_zone.#{kind}.title"),
        body: I18n.t("fictions.notice_zone.#{kind}.body")
      )
    end
  end
end
