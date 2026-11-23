# frozen_string_literal: true

module Admin
  # Folds one fiction tag into another (FictionTags::Merge) after an admin picks the surviving tag.
  class FictionTagMergesController < ApplicationController
    before_action :authenticate_user!, :verify_user_permissions
    before_action :set_source

    def new
      @targets = targets
    end

    def create
      target = targets.find_by(id: params[:target_id])
      if target.nil?
        return redirect_to new_admin_fiction_tag_merge_path(@source), alert: t('admin.fiction_tags.merge.no_target')
      end

      FictionTags::Merge.call(source: @source, target:)
      redirect_to admin_fiction_tags_path(filter: 'all'),
                  notice: t('admin.fiction_tags.merge.done', source: @source.name, target: target.name),
                  status: :see_other
    end

    private

    def set_source
      @source = FictionTag.find(params.expect(:fiction_tag_id))
    end

    # Hidden tags cannot receive a merge, and a tag cannot absorb itself.
    def targets
      FictionTag.active.where.not(id: @source.id).order(:name)
    end
  end
end
