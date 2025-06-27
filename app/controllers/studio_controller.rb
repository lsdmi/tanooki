# frozen_string_literal: true

class StudioController < ApplicationController
  include FictionQuery
  include StudioTabLoadable

  before_action :authenticate_user!
  before_action :set_active_tab

  def index
    load_tab_content
  end

  def set_tab_and_redirect
    session[:studio_tab] = params[:tab]
    redirect_to studio_index_path
  end

  def tab
    @active_tab = params[:id]
    load_tab_content
    render turbo_stream: turbo_stream_updates
  end

  private

  def turbo_stream_updates
    [
      turbo_stream.update('tabs', partial: 'studio/tab_list', locals: { active_tab: @active_tab }),
      turbo_stream.update('tab-content', partial: "studio/tabs/#{@active_tab}", locals: tab_content_locals)
    ]
  end

  def tab_content_locals
    {
      fictions: @fictions,
      pagy: @pagy,
      publications: @publications,
      pokemon_show: @pokemon_show,
      avatars: @avatars,
      comments: @comments,
      scanlators: @scanlators
    }
  end
end
