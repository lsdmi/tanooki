# frozen_string_literal: true

module Admin
  # Rolls chapter text back to before one key, or one connected chat, changed it.
  class ApiRollbacksController < ApplicationController
    before_action :authenticate_user!, :verify_user_permissions

    def index
      @tokens = ApiChangeSources.tokens
      @oauth = ApiChangeSources.oauth
    end

    def create
      result = RollbackTokenChanges.call(admin: current_user, revisions:, since:)
      redirect_to admin_api_rollbacks_path, notice: notice_for(result)
    rescue ArgumentError
      redirect_to admin_api_rollbacks_path, alert: t('admin.api_rollbacks.invalid_since')
    end

    private

    def revisions
      return ChapterRevision.where(api_token_id: params[:api_token_id]) if params[:api_token_id].present?
      return oauth_revisions if params[:oauth_application_id].present? && params[:user_id].present?

      ChapterRevision.none
    end

    def oauth_revisions
      ChapterRevision.where(user_id: params[:user_id], oauth_application_id: params[:oauth_application_id])
    end

    def since
      time = Time.zone.parse(params[:since].to_s)
      raise ArgumentError if time.nil?

      time
    end

    def notice_for(result)
      return t('admin.api_rollbacks.done', count: result.restored) unless result.failed.positive?

      t('admin.api_rollbacks.partial', restored: result.restored, failed: result.failed)
    end
  end
end
