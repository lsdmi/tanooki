# frozen_string_literal: true

module Admin
  module Contests
    # Post-factum intervention on contest entries (reject / disqualify) — not an approval queue.
    class EntriesController < ApplicationController
      before_action :authenticate_user!, :verify_user_permissions
      before_action :set_contest

      def index
        @entries = filtered_entries.includes(:fiction, :submitter).order(submitted_at: :desc)
        @status_filter = params[:status].presence
      end

      def update
        action = params.expect(:moderation).to_sym
        review_entry(action)
        redirect_to filtered_entries_path, notice: t("admin.contests.entries.notices.#{action}")
      rescue ::Contests::ReviewEntry::Error => e
        redirect_to admin_contest_entries_path(@contest), alert: e.message
      end

      private

      def set_contest
        @contest = Contest.find(params.expect(:contest_id))
      end

      def review_entry(action)
        entry = @contest.entries.find(params.expect(:id))
        ::Contests::ReviewEntry.call(entry:, actor: current_user, action:, reason: params[:reason])
      end

      def filtered_entries_path
        admin_contest_entries_path(@contest, request.query_parameters.slice('status'))
      end

      def filtered_entries
        scope = @contest.entries
        scope = scope.where(status: params[:status]) if params[:status].present?
        scope
      end
    end
  end
end
