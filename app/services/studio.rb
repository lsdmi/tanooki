# frozen_string_literal: true

# Namespace for Studio UI services. Defined here so Zeitwerk loads `Studio` before
# `Studio::TabContent` when callers use `Studio.normalize_tab_id` directly.
module Studio
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

  def self.tab_partial(tab)
    TAB_PARTIALS.fetch(normalize_tab_id(tab))
  end
end
