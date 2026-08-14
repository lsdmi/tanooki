# frozen_string_literal: true

module Chapters
  # Daily pass: compress inline images in chapters posted on the previous calendar day.
  # Enqueues one CompressInlineImagesJob per chapter, staggered so the compress queue
  # stays at most one heavy vips job at a time even before concurrency controls apply.
  class CompressRecentInlineImagesJob < ApplicationJob
    queue_as :default

    STAGGER = 45.seconds

    def perform(day: Time.current.to_date)
      return unless Rails.env.production?

      enqueued = enqueue_for_day(day)
      log_enqueue(day, enqueued)
    end

    private

    def enqueue_for_day(day)
      enqueued = 0
      posted_on(day - 1.day).find_each.with_index do |chapter, index|
        CompressInlineImagesJob.set(wait: index * STAGGER).perform_later(chapter.id)
        enqueued += 1
      end
      enqueued
    end

    def posted_on(date)
      range = date.all_day
      Chapter.where(Arel.sql("#{Chapter::PUBLIC_TIME_SQL} BETWEEN ? AND ?"), range.begin, range.end)
    end

    def log_enqueue(day, enqueued)
      range = (day - 1.day).all_day
      Rails.logger.info(
        '[CompressRecentInlineImagesJob] ' \
        "day=#{day} range=#{range.begin.iso8601}..#{range.end.iso8601} enqueued=#{enqueued} " \
        "stagger=#{STAGGER.inspect}"
      )
    end
  end
end
