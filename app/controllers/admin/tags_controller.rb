# frozen_string_literal: true

module Admin
  class TagsController < ApplicationController
    before_action :require_authentication, :verify_user_permissions

    def index
      @tag = Tag.new
      @tags = Tag.all.order(:name)
    end

    def create
      @tag = Tag.new(tag_params)
      render turbo_stream: (@tag.save ? [prepend_form, refresh_form(:persisted)] : refresh_form(:new))
    end

    def destroy
      tag = Tag.find(params[:id])
      tag.destroy
      render turbo_stream: refresh_list
    end

    def edit
      @tag = Tag.find(params[:id])
      render turbo_stream: edit_tag
    end

    def update
      @tag = Tag.find(params[:id])
      render turbo_stream: (@tag.update(tag_params) ? refresh_list : edit_tag)
    end

    private

    def tag_params
      params.require(:tag).permit(:name) if params[:tag]
    end

    def prepend_form
      turbo_stream.prepend('tags-list', partial: 'tag', locals: { tg: @tag })
    end

    def refresh_form(status)
      turbo_stream.update('new-tag-form', partial: 'new', locals: { tg: (status == :new ? @tag : Tag.new) })
    end

    def refresh_list
      turbo_stream.update('index-list', partial: 'list', locals: { tags: Tag.all.order(:name) })
    end

    def edit_tag
      turbo_stream.replace("tag-#{params[:id]}", partial: 'edit', locals: { tg: @tag })
    end
  end
end
