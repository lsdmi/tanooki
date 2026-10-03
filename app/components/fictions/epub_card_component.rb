# frozen_string_literal: true

module Fictions
  # Compact EPUB card in the About sidebar (Figma «EPUB / Login Download Banner» 4040:5904, Compact). Exports stay per
  # section in the Chapters tab (D7), so the card only points there; guests get a login prompt instead.
  # Shown only when some section allows EPUB.
  class EpubCardComponent < ViewComponent::Base
    include Ui::StrokeIconHelper

    def initialize(fiction:, user:)
      super()
      @fiction = fiction
      @user = user
    end

    def render?
      Library::ReadingState.fiction_epub_download_support(fiction, viewer: user) != :none
    end

    private

    attr_reader :fiction, :user

    def href
      user ? '#chapters' : new_user_session_path(return_to: fiction_path(fiction, anchor: 'chapters'))
    end

    def link_data
      user ? { action: 'tabs#jump', tabs_tab_param: 'chapters' } : {}
    end

    def hint
      t(user ? 'hint' : 'login_hint', scope: 'fictions.about.epub')
    end
  end
end
