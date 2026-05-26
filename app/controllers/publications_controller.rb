# frozen_string_literal: true

# Handles authenticated creation, editing, and deletion of blog-style publications.
class PublicationsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_publication, only: %i[edit update destroy]
  before_action :set_tags, only: %i[new create edit update]
  before_action :verify_permissions, except: %i[new create]

  def new
    @publication = Publication.new
  end

  def edit; end

  def create
    @publication = current_user.publications.build(publication_params)

    if @publication.save
      manage_tags if params[:publication][:tag_ids]
      redirect_to root_path, notice: t('publications.notices.create_success')
    else
      render 'publications/new', status: :unprocessable_content
    end
  end

  def update
    if @publication.update(publication_params)
      manage_tags if params[:publication][:tag_ids]
      redirect_to tale_path(@publication), notice: t('publications.notices.update_success')
    else
      render 'sweetalert/edit', status: :unprocessable_content
    end
  end

  def destroy
    @publication.destroy
    @pagy, @publications = pagy(
      publications,
      limit: 8,
      request_path: blogs_path,
      page: params[:page] || 1
    )

    render turbo_stream: [refresh_list, refresh_sweetalert]
  end

  private

  def publications
    if current_user.admin?
      Publication.order(created_at: :desc)
    else
      current_user.publications.order(created_at: :desc)
    end
  end

  def manage_tags
    existing_tag_ids = @publication.tags.ids

    tags_to_add = publication_tags_ids - existing_tag_ids
    tags_to_remove = existing_tag_ids - publication_tags_ids

    tags_to_add.each { |tag_id| @publication.publication_tags.create(tag_id:) }
    tags_to_remove.each { |tag_id| @publication.publication_tags.find_by(tag_id:).destroy }
  end

  def publication_params
    params.expect(publication: [:type, :title, :description, :cover, :highlight, { tag_ids: [] }])
  end

  def publication_tags_ids
    @publication_tags_ids ||= params[:publication][:tag_ids].compact_blank.map(&:to_i)
  end

  def set_publication
    @publication = Publication.friendly.find(params[:id])
  end

  def set_tags
    @tags = Tag.order(:name)
  end

  def verify_permissions
    redirect_to root_path unless current_user.admin? || current_user.publications.include?(@publication)
  end

  def refresh_list
    turbo_stream.update(
      'publications-list',
      partial: 'users/dashboard/publications',
      locals: { publications: @publications, pagy: @pagy }
    )
  end
end
