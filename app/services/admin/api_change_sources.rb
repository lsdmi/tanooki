# frozen_string_literal: true

module Admin
  # Keys and connected chats that have stored a chapter revision an admin can roll back.
  class ApiChangeSources
    TokenSource = Data.define(:token, :count)
    OauthSource = Data.define(:user, :application, :count)

    def self.tokens
      counts = ChapterRevision.where.not(api_token_id: nil).group(:api_token_id).count
      ApiToken.where(id: counts.keys).includes(:user).map do |token|
        TokenSource.new(token:, count: counts[token.id])
      end
    end

    def self.oauth
      counts = ChapterRevision.where.not(oauth_application_id: nil).group(:user_id, :oauth_application_id).count
      rows_for(counts)
    end

    def self.rows_for(counts)
      return [] if counts.empty?

      users, apps = owners(counts.keys)
      counts.filter_map { |(user_id, app_id), count| oauth_source(users[user_id], apps[app_id], count) }
    end

    def self.owners(keys)
      user_ids, app_ids = keys.transpose
      [User.where(id: user_ids).index_by(&:id), Doorkeeper::Application.where(id: app_ids).index_by(&:id)]
    end

    def self.oauth_source(user, application, count)
      return if user.nil? || application.nil?

      OauthSource.new(user:, application:, count:)
    end

    private_class_method :rows_for, :owners, :oauth_source
  end
end
