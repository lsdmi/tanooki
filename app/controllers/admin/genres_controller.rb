# frozen_string_literal: true

module Admin
  # Manages fiction genres via Turbo Stream CRUD.
  class GenresController < ApplicationController
    before_action :authenticate_user!, :verify_user_permissions

    def index
      @genre = Genre.new
      @genres = Genre.order(:name)
    end

    def edit
      @genre = Genre.find(params.expect(:id))
      render turbo_stream: edit_genre
    end

    def create
      @genre = Genre.new(genre_params)
      render turbo_stream: (@genre.save ? [prepend_form, refresh_form(:persisted)] : refresh_form(:new))
    end

    def update
      @genre = Genre.find(params.expect(:id))
      render turbo_stream: (@genre.update(genre_params) ? refresh_list : edit_genre)
    end

    def destroy
      genre = Genre.find(params.expect(:id))
      genre.destroy
      render turbo_stream: turbo_stream_list_refresh(refresh_list)
    end

    private

    def genre_params
      params.expect(genre: [:name])
    end

    def prepend_form
      turbo_stream.prepend('genres-list', partial: 'genre', locals: { genre: @genre })
    end

    def refresh_form(status)
      turbo_stream.update('new-genre-form', partial: 'new', locals: { genre: (status == :new ? @genre : Genre.new) })
    end

    def refresh_list
      turbo_stream.update('index-list', partial: 'list', locals: { genres: Genre.order(:name) })
    end

    def edit_genre
      turbo_stream.replace("genre-#{params[:id]}", partial: 'edit', locals: { genre: @genre })
    end
  end
end
