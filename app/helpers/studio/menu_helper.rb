# frozen_string_literal: true

module Studio
  # Sidebar / tab strip entries for the studio area (+id+, +label+, +icon+ asset basename).
  # Icons: withicons-anime (MIT) via Iconify — app/assets/images/studio/*.svg
  module MenuHelper
    MENU_ITEMS = [
      { id: 'blogs', label: 'Блоги', icon: 'blogs' },
      { id: 'teams', label: 'Команди', icon: 'teams' },
      { id: 'writings', label: 'Писальня', icon: 'writings' },
      { id: 'pokemons', label: 'Покемони', icon: 'pokemons' },
      { id: 'bookshelves', label: 'Полиці', icon: 'bookshelves' },
      { id: 'epub_exports', label: 'EPUB', icon: 'epub_exports' },
      { id: 'profile', label: 'Профіль', icon: 'profile' },
      { id: 'notifications', label: 'Сповіщення', icon: 'notifications' }
    ].freeze

    def studio_menu_items
      count = studio_paragraph_reports_badge_count
      MENU_ITEMS.map do |item|
        next item unless item[:id] == 'notifications'

        item.merge(badge: (count if count&.positive?))
      end
    end

    def studio_tab_icon(item)
      image_tag(
        "studio/#{item[:icon]}.svg",
        class: 'h-6 w-6',
        alt: '',
        aria: { hidden: true },
        draggable: false
      )
    end

    def studio_paragraph_reports_badge_count
      return unless ParagraphReportsAccess.allowed?(current_user)

      ParagraphReports::InboxCollector.new(current_user).open_count
    end
  end
end
