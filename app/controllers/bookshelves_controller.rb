# frozen_string_literal: true

class BookshelvesController < ApplicationController
  before_action :authenticate_user!, except: %i[index show]
  before_action :set_bookshelf, only: %i[show edit update destroy]
  before_action :track_visit, only: :show

  def index; end

  def show
    @pagy, @fictions = pagy(@bookshelf.fictions.includes(:cover_attachment, :genres), limit: 20)
    @advertisement = Advertisement.enabled.includes(:cover_attachment, :poster_attachment).sample
  end

  def new
    @bookshelf = current_user.bookshelves.build
    @fictions = Fiction.all.order(:title)
  end

  def create
    @bookshelf = current_user.bookshelves.build(bookshelf_params)
    @fictions = Fiction.all.order(:title)

    if @bookshelf.save
      redirect_to studio_index_path(tab: 'bookshelves'), notice: 'Полицю дадано'
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    @fictions = Fiction.all.order(:title)
    @bookshelf.fiction_ids = @bookshelf.fictions.pluck(:id)
  end

  def update
    @fictions = Fiction.all.order(:title)

    if @bookshelf.update(bookshelf_params)
      redirect_to studio_index_path(tab: 'bookshelves'), notice: 'Полицю оновлено!'
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @bookshelf.destroy
    @bookshelves = current_user.bookshelves.ordered
    render turbo_stream: [refresh_list, refresh_sweetalert]
  end

  private

  def set_bookshelf
    @bookshelf = if action_name == 'show'
                   Bookshelf.find_by_sqid(params[:sqid])
                 else
                   current_user.bookshelves.find(params[:sqid])
                 end
  end

  def bookshelf_params
    params.require(:bookshelf).permit(:title, :description, fiction_ids: [])
  end

  def refresh_list
    turbo_stream.update(
      'bookshelves-list',
      partial: 'studio/tabs/bookshelves',
      locals: { bookshelves: @bookshelves }
    )
  end
end
