# frozen_string_literal: true

module Fictions
  # Notices above the fiction hero: an optional age notice, then at most one status notice
  # derived from the listing state (ongoing works get none).
  module NoticeZone
    Notice = Data.define(:kind, :title, :body)

    AGE_KINDS = { 'eighteen' => :adult, 'sixteen' => :teen }.freeze
    STATUS_KINDS = { stale: :dropped, announced: :announced, finished: :finished }.freeze

    module_function

    def for(fiction, age: true)
      age_kind = AGE_KINDS[fiction.content_rating] if age
      [age_kind, STATUS_KINDS[fiction.listing_state]].compact.map { |kind| notice(kind) }
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
