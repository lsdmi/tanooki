# frozen_string_literal: true

class PublicationsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_publication, only: %i[update destroy]
  before_action :verify_permissions

  def create
    @publication = Publication.new(publication_params)

    if @publication.save
      manage_tags if params[:publication][:tag_ids]
      redirect_to root_path, notice: 'Звістку створено.'
    else
      render 'admin/tales/new', status: :unprocessable_entity
    end
  end

  def update
    if @publication.update(publication_params)
      manage_tags if params[:publication][:tag_ids]
      redirect_to tale_path(@publication), notice: 'Звістку оновлено.'
    else
      render 'admin/tales/edit', status: :unprocessable_entity
    end
  end

  def destroy
    @publication.destroy
    redirect_to root_path, notice: 'Звістку видалено.'
  end

  private

  def manage_tags
    publication_tags_ids = params[:publication][:tag_ids].map(&:to_i)
    existing_tag_ids = @publication.tags.ids

    tags_to_add = publication_tags_ids - existing_tag_ids
    tags_to_remove = existing_tag_ids - publication_tags_ids

    tags_to_add.each { |tag_id| @publication.publication_tags.create(tag_id:) }
    tags_to_remove.each { |tag_id| @publication.publication_tags.find_by(tag_id:).destroy }
  end

  def publication_params
    params.require(:publication).permit(
      :type, :title, :description, :cover, :highlight, :user_id
    )
  end

  def set_publication
    @publication = Publication.find(params[:id])
  end

  def verify_permissions
    redirect_to root_path if not_admin_user?
  end

  def not_admin_user?
    publication_type == 'Tale' && !current_user.admin?
  end

  def publication_type
    @publication&.type || publication_params[:type]
  end

  def publication_user_id
    @publication&.user_id || publication_params[:user_id]
  end
end
