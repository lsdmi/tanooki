# frozen_string_literal: true

module Admin
  class TagsController < ApplicationController
    before_action :set_new_tag, only: %i[index destroy attach detach]

    def index
      @tags = Tag.all.order(:name)
      @publications = Publication.all.order(created_at: :desc)
    end

    def create
      @tag = Tag.new(tag_params)
      render turbo_stream: (@tag.save ? [prepend_form, refresh_form(:persisted)] : refresh_form(:new))
    end

    def destroy
      tag = Tag.find(params[:id])
      tag.destroy
      render turbo_stream: [refresh_list, refresh_publications]
    end

    def edit
      @tag = Tag.find(params[:id])
      render turbo_stream: edit_tag
    end

    def update
      @tag = Tag.find(params[:id])
      render turbo_stream: (@tag.update(tag_params) ? refresh_list : edit_tag)
    end

    def attach
      if publication_tags_params
        publication_ids = params.dig(:tag, :publication_id)
        find_or_create_publication_tags(publication_ids, params[:tag_id])
        render turbo_stream: [refresh_list, refresh_publications]
      else
        @tag = Tag.find(params[:tag_id])
        @tag.errors.add(:publication_id, 'долучіть публікації')
        render turbo_stream: [show_tag]
      end
    end

    def detach
      publication_tag = PublicationTag.find(params[:id])
      publication_tag.destroy
      render turbo_stream: refresh_publications
    end

    private

    def tag_params
      params.require(:tag).permit(:name) if params[:tag]
    end

    def publication_tags_params
      params.require(:tag).permit(:publication_id) if params[:tag]
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

    def refresh_publications
      turbo_stream.update(
        'publications-form',
        partial: 'publications', locals: { publications: Publication.all.order(created_at: :desc) }
      )
    end

    def edit_tag
      turbo_stream.replace("tag-#{params[:id]}", partial: 'edit', locals: { tg: @tag })
    end

    def show_tag
      turbo_stream.replace("tag-#{params[:tag_id]}", partial: 'tag', locals: { tg: @tag })
    end

    def set_new_tag
      @tag = Tag.new
    end

    def find_or_create_publication_tags(publication_ids, tag_id)
      PublicationTag.transaction do
        publication_ids.each do |publication_id|
          PublicationTag.find_or_create_by(publication_id:, tag_id:)
        end
      end
    end
  end
end
