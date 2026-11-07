# frozen_string_literal: true

module Admin
  # JSON options for the contest juror picker. The form must not render every user.
  class UserSearch
    LIMIT = 30

    class << self
      def call(query:)
        scope = User.order(:name)
        stripped = query.to_s.strip
        scope = scope.where('name LIKE ?', "%#{User.sanitize_sql_like(stripped)}%") if stripped.present?
        scope.limit(LIMIT).map { |user| { text: user.name, value: user.id.to_s } }
      end
    end
  end
end
