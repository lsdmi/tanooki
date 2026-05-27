# frozen_string_literal: true

module Admin
  # Manages selectable user avatars via Turbo Stream CRUD.
  class AvatarsController < ApplicationController
    before_action :authenticate_user!, :verify_user_permissions

    def index
      @avatars = Avatar.order(created_at: :desc)
      @avatar = Avatar.new
    end

    def create
      @avatar = Avatar.new(avatar_params)

      respond_to do |format|
        format.turbo_stream do
          @avatar.save ? prepend_avatar_and_refresh_form : refresh_form
        end
      end
    end

    def destroy
      avatar = Avatar.find(params[:id])
      avatar.destroy

      respond_to do |format|
        format.turbo_stream do
          render turbo_stream: turbo_stream.remove("avatar-#{avatar.id}")
        end
      end
    end

    private

    def avatar_params
      params.expect(avatar: [:image])
    end

    def prepend_avatar_and_refresh_form
      render turbo_stream: [
        turbo_stream.prepend(
          'avatar-list',
          partial: 'avatar', locals: { avatar: @avatar }
        ),
        turbo_stream.update(
          'avatar-form',
          partial: 'form', locals: { avatar: Avatar.new }
        )
      ]
    end

    def refresh_form
      render turbo_stream: [
        turbo_stream.update(
          'avatar-form',
          partial: 'form', locals: { avatar: @avatar }
        )
      ]
    end
  end
end
