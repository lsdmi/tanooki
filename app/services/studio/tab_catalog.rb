# frozen_string_literal: true

module Studio
  # Known Studio dashboard tabs: stable ids and the partial path used to render each tab body.
  class TabCatalog
    TAB_PARTIALS = {
      'blogs' => 'studio/tabs/blogs',
      'pokemons' => 'studio/tabs/pokemons',
      'teams' => 'studio/tabs/teams',
      'writings' => 'studio/tabs/writings',
      'notifications' => 'studio/tabs/notifications',
      'profile' => 'studio/tabs/profile',
      'bookshelves' => 'studio/tabs/bookshelves'
    }.freeze

    def self.normalize_tab_id(tab, fallback: 'blogs')
      id = tab.to_s
      TAB_PARTIALS.key?(id) ? id : fallback
    end

    def self.partial_for(tab)
      TAB_PARTIALS.fetch(normalize_tab_id(tab))
    end
  end
end
