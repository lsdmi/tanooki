# frozen_string_literal: true

# Intentional Bullet skips for the test suite (Bullet.raise). Prefer a real preload when the association is used.
# Each entry needs a short why.

# Nested replies soft-delete via dependent: :destroy; destroy_all on parents loads them one parent at a time.
Bullet.add_safelist type: :n_plus_one_query, class_name: 'Comment', association: :replies

# Navbar reads current_user.avatar once; Bullet still flags it when the same request also loads other User rows.
Bullet.add_safelist type: :n_plus_one_query, class_name: 'User', association: :avatar

# Chapter form and translation-request cards read current_user.scanlators; other User rows in the same request
# (authors, assignees) make Bullet treat that as an N+1 even after .load on current_user.
Bullet.add_safelist type: :n_plus_one_query, class_name: 'User', association: :scanlators

# really_destroy! on a fiction walks each chapter's dependent: :destroy associations with no bulk preload.
%i[images_attachments chapter_scanlators revisions comments readings rich_text_content].each do |association|
  Bullet.add_safelist type: :n_plus_one_query, class_name: 'Chapter', association: association
end

# Shared catalog/show includes: many controller tests hit redirects, Turbo streams, or JSON and never touch every
# association the HTML path needs. Development still reports unused eager loads in the footer.
%i[
  genres fiction_genres fiction_ratings fiction_scanlators scanlators
  cover_attachment banner_attachment
].each do |association|
  Bullet.add_safelist type: :unused_eager_loading, class_name: 'Fiction', association: association
end

# Chapter lists preload teams for the row UI; authorization and stats tests often skip that partial.
Bullet.add_safelist type: :unused_eager_loading, class_name: 'Chapter', association: :scanlators
Bullet.add_safelist type: :unused_eager_loading, class_name: 'Chapter', association: :chapter_scanlators
Bullet.add_safelist type: :unused_eager_loading, class_name: 'Chapter', association: :fiction

# Tale index/show preload; some actions only check response status.
Bullet.add_safelist type: :unused_eager_loading, class_name: 'Tale', association: :cover_attachment

# next_for preloads the target for the Studio details UI; service tests often stop at the evolution row.
Bullet.add_safelist type: :unused_eager_loading, class_name: 'PokemonEvolution', association: :to

# Wild catch loads the sprite for the encounter frame; unit helpers call encounter without rendering.
Bullet.add_safelist type: :unused_eager_loading, class_name: 'Pokemon', association: :sprite_attachment

# Details helpers preload the species; some tests only assert ids.
Bullet.add_safelist type: :unused_eager_loading, class_name: 'UserPokemon', association: :pokemon

# Avatar image when a page loads Avatar without showing the picture.
Bullet.add_safelist type: :unused_eager_loading, class_name: 'Avatar', association: :image_attachment

# Nested Active Storage includes for sprites/covers when the test does not render the image tag.
Bullet.add_safelist type: :unused_eager_loading, class_name: 'ActiveStorage::Attachment', association: :blob
Bullet.add_safelist type: :unused_eager_loading, class_name: 'ActiveStorage::Blob', association: :variant_records
Bullet.add_safelist type: :unused_eager_loading, class_name: 'ActiveStorage::Blob',
                    association: :preview_image_attachment

# Battle and details preload types for the UI; the engine snapshot only needs combatant stats.
Bullet.add_safelist type: :unused_eager_loading, class_name: 'Pokemon', association: :pokemon_types
Bullet.add_safelist type: :unused_eager_loading, class_name: 'Pokemon', association: :pokemon_type_relations

# Reading history and Studio battle history: associations for the HTML path, unused in service-only tests.
Bullet.add_safelist type: :unused_eager_loading, class_name: 'Scanlator', association: :avatar_attachment
Bullet.add_safelist type: :unused_eager_loading, class_name: 'ReadingProgress', association: :chapter
Bullet.add_safelist type: :unused_eager_loading, class_name: 'ReadingProgress', association: :fiction
Bullet.add_safelist type: :unused_eager_loading, class_name: 'PokemonBattle', association: :winner
Bullet.add_safelist type: :unused_eager_loading, class_name: 'PokemonBattle', association: :attacker
Bullet.add_safelist type: :unused_eager_loading, class_name: 'PokemonBattle', association: :defender
Bullet.add_safelist type: :unused_eager_loading, class_name: 'TranslationRequest', association: :user
Bullet.add_safelist type: :unused_eager_loading, class_name: 'TranslationRequest', association: :scanlator
Bullet.add_safelist type: :unused_eager_loading, class_name: 'Bookshelf', association: :bookshelf_fictions
