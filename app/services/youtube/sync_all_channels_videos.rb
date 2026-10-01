# frozen_string_literal: true

require 'google/apis/errors'

module Youtube
  # Daily pass (Youtube::SyncAllChannelsJob) or operator rake: sync latest videos for every YoutubeChannel inline.
  class SyncAllChannelsVideos
    Result = Data.define(:channel_ids, :synced, :errors)
    RETRY_DELAY_SECONDS = 5

    def self.call
      new.call
    end

    def call
      ids = YoutubeChannel.order(:id).pluck(:channel_id)
      tallies = sync_all(ids)
      Result.new(channel_ids: ids, **tallies)
    end

    private

    def sync_all(ids)
      tallies = { synced: 0, errors: [] }
      ids.each { |channel_id| record_outcome!(tallies, sync_one(channel_id)) }
      tallies
    end

    def record_outcome!(tallies, outcome)
      case outcome
      when :synced then tallies[:synced] += 1
      else tallies[:errors] << outcome
      end
    end

    def sync_one(channel_id)
      sync_with_retry(channel_id)
      Rails.logger.info("[SyncAllChannelsVideos] channel=#{channel_id} synced")
      :synced
    rescue StandardError => e
      Rails.logger.error("[SyncAllChannelsVideos] channel=#{channel_id} #{e.class}: #{e.message}")
      { channel_id:, error: "#{e.class}: #{e.message}" }
    end

    # YouTube occasionally answers valid requests with a spurious 403 for a few seconds.
    def sync_with_retry(channel_id)
      SyncChannelVideos.call(channel_id)
    rescue Google::Apis::Error => e
      Rails.logger.warn("[SyncAllChannelsVideos] channel=#{channel_id} retrying after #{e.class}: #{e.message}")
      sleep(RETRY_DELAY_SECONDS)
      SyncChannelVideos.call(channel_id)
    end
  end
end
