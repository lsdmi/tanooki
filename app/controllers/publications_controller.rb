# frozen_string_literal: true

class PublicationsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_publication, only: :update
  before_action :verify_user_permissions

  def create
    @publication = Publication.new(publication_params)

    if @publication.save
      redirect_to root_path, notice: create_notice
    else
      render new_publication_partial, status: :unprocessable_entity
    end
  end

  def update
    if @publication.update(publication_params)
      redirect_to update_redirect_path, notice: update_notice
    else
      render edit_publication_partial, status: :unprocessable_entity
    end
  end

  private

  def create_notice
    @publication.instance_of?(Blog) ? 'пост надіслано на модерацію' : 'звістку створено'
  end

  def update_notice
    @publication.instance_of?(Blog) ? 'пост надіслано на модерацію' : 'звістку оновлено'
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
    params.require(:publication).permit(:type, :title, :description, :cover, :highlight, :user_id)
  end

  def set_publication
    @publication = Publication.find(params[:id])
  end

  def verify_user_permissions
    if (
      @publication.type == 'Blog' && action_name.to_sym == :update && @publication.user_id != current_user.id
    ) || (
      @oublication.type == 'Tale' && !current_user.admin?
    )
      redirect_to root_path
    end
  end
end
