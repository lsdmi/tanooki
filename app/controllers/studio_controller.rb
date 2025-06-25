# frozen_string_literal: true

class StudioController < ApplicationController
  def index
    @active_tab = params[:tab] || 'blogs'
  end

  def tab
    @active_tab = params[:id]
    render turbo_stream: turbo_stream_updates(@active_tab)
  end

  private

  def turbo_stream_updates(active_tab)
    [
      turbo_stream.update('tabs', partial: 'studio/tab_list', locals: { active_tab: active_tab }),
      turbo_stream.update('tab-content', partial: "studio/tabs/#{active_tab}",
                                         locals: { fictions: @fictions, pagy: @pagy })
    ]
  end
end
