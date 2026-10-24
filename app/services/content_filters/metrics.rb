# frozen_string_literal: true

module ContentFilters
  # How many readers turned a filter on, and which packages they chose. Guest cookies are not stored.
  class Metrics
    Result = Data.define(:readers, :filtered, :top, :guest_no18)
    TOP_GENRES = 8

    def self.call
      new.call
    end

    def call
      Result.new(readers: User.count, filtered: filtered_reader_count, top: top_packages, guest_no18: nil)
    end

    private

    def filtered_reader_count
      rating_ids = UserContentFilter.where.not(max_content_rating: nil).distinct.pluck(:user_id)
      package_ids = UserHiddenPackage.distinct.pluck(:user_id)
      (rating_ids | package_ids).size
    end

    def top_packages
      counts = UserHiddenPackage.group(:package_key).order(Arel.sql('COUNT(*) DESC')).limit(TOP_GENRES).count
      counts.transform_keys { |key| I18n.t("content_filters.packages.#{key}.name") }
    end
  end
end
