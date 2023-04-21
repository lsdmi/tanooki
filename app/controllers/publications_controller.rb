# frozen_string_literal: true

class PublicationsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_publication, only: %i[update destroy]
  before_action :verify_permissions

  def create
    @publication = Publication.new(publication_params)

    if @publication.save
      manage_tags
      redirect_to root_path, notice: create_notice
    else
      render new_publication_partial, status: :unprocessable_entity
    end
  end

  def update
    if @publication.update(publication_params)
      manage_tags
      redirect_to update_redirect_path, notice: update_notice
    else
      render edit_publication_partial, status: :unprocessable_entity
    end
  end

  def destroy
    @publication.destroy
    redirect_to root_path, notice: destroy_notice
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

  def create_notice
    @publication.instance_of?(Blog) ? 'Допис надіслано на модерацію.' : 'Звістку створено.'
  end

  def update_notice
    @publication.instance_of?(Blog) ? 'Допис надіслано на модерацію.' : 'Звістку оновлено.'
  end

  def destroy_notice
    @publication.instance_of?(Blog) ? 'Допис видалено.' : 'Звістку видалено.'
  end

  def new_publication_partial
    @publication.instance_of?(Blog) ? 'blogs/new' : 'admin/tales/new'
  end

  def edit_publication_partial
    @publication.instance_of?(Blog) ? 'blogs/edit' : 'admin/tales/edit'
  end

  def update_redirect_path
    @publication.instance_of?(Blog) ? blog_path(@publication) : tale_path(@publication)
  end

  def publication_params
    params.require(:publication).permit(
      :type, :title, :description, :cover, :highlight, :user_id, :status, :status_message
    )
  end

  def set_publication
    @publication = Publication.find(params[:id])
  end

  def verify_permissions
    redirect_to root_path if not_blog_author? || not_admin_user?
  end

  def not_blog_author?
    publication_type == 'Blog' &&
      (action_name.to_sym == :update || action_name.to_sym == :destroy) &&
      publication_user_id != current_user.id
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
