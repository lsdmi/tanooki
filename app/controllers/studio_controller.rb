# frozen_string_literal: true

# Translator studio dashboard for managing fictions and chapters.
class StudioController < ApplicationController
  helper Pokemons::DexHelper,
         Pokemons::StatsHelper,
         Studio::MenuHelper

  include FictionQuery
  include StudioTabLoadable

  before_action :authenticate_user!
  before_action :set_active_tab

  def index
    load_tab_content
  end

  def set_tab_and_redirect
    session[:studio_tab] = Studio::TabCatalog.normalize_tab_id(params[:tab])
    redirect_to studio_index_path
  end

  def tab
    @active_tab = Studio::TabCatalog.normalize_tab_id(params[:id])
    session[:studio_tab] = @active_tab
    load_tab_content
    render turbo_stream: turbo_stream_updates
  end

  private

  def turbo_stream_updates
    turbo_stream_with_cleared_flash(
      turbo_stream.update('tabs', partial: 'studio/tab_list', locals: { active_tab: @active_tab }),
      turbo_stream.update(
        'tab-content',
        partial: Studio::TabCatalog.partial_for(@active_tab),
        locals: tab_content_locals
      )
    )
  end

  def tab_content_locals
    {
      fictions: @fictions, pagy: @pagy, publications: @publications, pokemon_show: @pokemon_show,
      avatars: @avatars, comments: @comments, scanlators: @scanlators,
      bookshelves: @bookshelves, epub_export_requests: @epub_export_requests,
      cover_quality_flags: @cover_quality_flags
    }
  end
end
