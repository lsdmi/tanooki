# frozen_string_literal: true

module ContentFilters
  # Replaces an account's rating cap and packages in one transaction.
  class Replace
    RATINGS = { nil => nil, '' => nil, '0' => 0, '16' => 16, 0 => 0, 16 => 16 }.freeze
    Result = Data.define(:error) do
      def success?
        error.nil?
      end
    end

    def self.call(user:, max_content_rating:, package_keys:)
      new(user:, max_content_rating:, package_keys:).call
    end

    def initialize(user:, max_content_rating:, package_keys:)
      @user = user
      @max_content_rating = max_content_rating
      @package_keys = package_keys
    end

    def call
      error = validation_error
      return Result.new(error:) if error

      persist
      Result.new(error: nil)
    end

    private

    def validation_error
      return I18n.t('content_filters.errors.rating') unless RATINGS.key?(@max_content_rating)
      return I18n.t('content_filters.errors.cap') if keys.size > Packages::MAX
      return I18n.t('content_filters.errors.package') if keys.any? { |key| !Packages.key?(key) }

      nil
    end

    def persist
      @user.transaction do
        sync_rating
        @user.hidden_packages.delete_all
        keys.each { |key| @user.hidden_packages.create!(package_key: key) }
      end
    end

    def sync_rating
      filter = @user.content_filter
      if rating.nil?
        filter&.destroy!
        return
      end

      filter ||= @user.build_content_filter
      filter.update!(max_content_rating: rating)
    end

    def rating
      RATINGS[@max_content_rating]
    end

    def keys
      @keys ||= Array(@package_keys).map(&:to_s).uniq
    end
  end
end
