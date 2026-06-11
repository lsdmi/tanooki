# frozen_string_literal: true

module Fictions
  # Cached hot-update fiction lists for the fictions index.
  module IndexHotUpdates
    module_function

    def fictions
      ids = cached_ids
      return Fiction.none if ids.blank?

      Fiction.where(id: ids)
             .includes({ cover_attachment: :blob })
             .in_order_of(:id, ids)
    end

    def counts
      Rails.cache.fetch('hot_updates_counts', expires_in: 12.hours) do
        ReadingProgress.where(created_at: 1.month.ago..Time.zone.now)
                       .group(:fiction_id)
                       .count
      end
    end

    def cached_ids
      Rails.cache.fetch('hot_updates_ids', expires_in: 12.hours) do
        ranked_scope.to_a.map(&:id)
      end
    end
    private_class_method :cached_ids

    def ranked_scope
      Fiction.joins(:readings)
             .group(:id)
             .where(readings: { created_at: 1.month.ago..Time.zone.now })
             .order(Arel.sql('COUNT(readings.fiction_id) DESC'))
    end
    private_class_method :ranked_scope
  end
end
