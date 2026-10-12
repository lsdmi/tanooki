# frozen_string_literal: true

module Admin
  # Candidate duplicate fictions, with merge and «not a duplicate» for an admin.
  class FictionDuplicatesController < ApplicationController
    before_action :authenticate_user!, :verify_user_permissions

    def index
      @groups = Fictions::DuplicateGroups.new.call.map { |rows| [rows, survivor(rows)] }
    end

    def merge
      rows = candidate_rows
      return stale_group unless rows

      redirect_to admin_fiction_duplicates_path, notice: merge_notice(rows)
    rescue ArgumentError
      redirect_to admin_fiction_duplicates_path, alert: t('admin.fiction_duplicates.merge_action.failed')
    end

    def dismiss
      rows = candidate_rows
      return stale_group unless rows

      FictionDuplicateDismissal.dismiss(rows.map(&:fiction), user: current_user)
      redirect_to admin_fiction_duplicates_path, notice: t('admin.fiction_duplicates.dismiss_action.done')
    end

    private

    def candidate_rows
      Fictions::DuplicateGroups.find(fiction_ids)
    end

    def fiction_ids
      Array(params[:fiction_ids]).map(&:to_i)
    end

    def survivor(rows)
      readers = rows.to_h { |row| [row.fiction.id, row.readers] }
      Fictions::DuplicateSurvivor.call(rows.map(&:fiction), readers:)
    end

    def merge_notice(rows)
      target = survivor(rows)
      sources = rows.map(&:fiction).reject { |fiction| fiction.id == target.id }
      sources.each { |source| Fictions::Merge.call(source:, target:, admin: current_user) }
      t('admin.fiction_duplicates.merge_action.done', title: target.title, count: sources.size)
    end

    def stale_group
      redirect_to admin_fiction_duplicates_path, alert: t('admin.fiction_duplicates.stale')
    end
  end
end
