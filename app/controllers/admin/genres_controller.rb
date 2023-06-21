# frozen_string_literal: true

module Admin
  class GenresController < ApplicationController
    before_action :authenticate_user!, :verify_user_permissions

    def index
      @genre = Genre.new
      @genres = Genre.all.order(:name)
    end

    def create
      @genre = Genre.new(genre_params)
      render turbo_stream: (@genre.save ? [prepend_form, refresh_form(:persisted)] : refresh_form(:new))
    end

    def destroy
      genre = Genre.find(params[:id])
      genre.destroy
      render turbo_stream: refresh_list
    end

    def edit
      @genre = Genre.find(params[:id])
      render turbo_stream: edit_genre
    end

    def update
      @genre = Genre.find(params[:id])
      render turbo_stream: (@genre.update(genre_params) ? refresh_list : edit_genre)
    end

    private

    def genre_params
      params.require(:genre).permit(:name) if params[:genre]
    end

    def prepend_form
      turbo_stream.prepend('genres-list', partial: 'genre', locals: { genre: @genre })
    end

    def refresh_form(status)
      turbo_stream.update('new-genre-form', partial: 'new', locals: { genre: (status == :new ? @genre : Genre.new) })
    end

    def refresh_list
      turbo_stream.update('index-list', partial: 'list', locals: { genres: Genre.all.order(:name) })
    end

    def edit_genre
      turbo_stream.replace("genre-#{params[:id]}", partial: 'edit', locals: { genre: @genre })
    end
  end
end
