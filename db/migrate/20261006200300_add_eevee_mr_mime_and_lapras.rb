# frozen_string_literal: true

# The Gen 1 species that were missing, legendaries aside: Mr. Mime, Lapras and Eevee, whose branch follows the
# Pokémon's trait (sturdy ones become Vaporeon, quick and lucky ones Jolteon, attackers Flareon). Sprites come from the
# same set as the others (db/pokemon_sprites). Stats are the official ones (config/pokemon_base_stats.yml).
# Eevee's forms keep rarity 5 and every new species is final in the old columns, so the code still running during
# the deploy keeps the forms out of the wild and never evolves Eevee.
class AddEeveeMrMimeAndLapras < ActiveRecord::Migration[8.1]
  SPRITES = Rails.root.join('db/pokemon_sprites')
  EEVEE_LEVEL = 30

  SPECIES = [
    { dex_id: 122, name: 'Містер Майм', slug: 'mister-maim', sprite: 'mr-mime.gif', types: %w[psychic],
      base_hp: 40, base_attack: 100, rarity: 4 },
    { dex_id: 131, name: 'Лапрас', slug: 'lapras', sprite: 'lapras.gif', types: %w[water ice],
      base_hp: 130, base_attack: 85, rarity: 4 },
    { dex_id: 133, name: 'Іві', slug: 'ivi', sprite: 'eevee.gif', types: %w[normal],
      base_hp: 55, base_attack: 55, rarity: 4 },
    { dex_id: 134, name: 'Вейпореон', slug: 'veiporeon', sprite: 'vaporeon.gif', types: %w[water],
      base_hp: 130, base_attack: 110, rarity: 5, from: 133, characters: %w[friendly hardy patient persistent] },
    { dex_id: 135, name: 'Джолтеон', slug: 'dzholteon', sprite: 'jolteon.gif', types: %w[electric],
      base_hp: 65, base_attack: 110, rarity: 5, from: 133, characters: %w[agile decisive independent lucky] },
    { dex_id: 136, name: 'Флереон', slug: 'flereon', sprite: 'flareon.gif', types: %w[fire],
      base_hp: 65, base_attack: 130, rarity: 5, from: 133, characters: %w[ambitious brave confident prideful] }
  ].freeze

  class Species < ActiveRecord::Base
    self.table_name = 'pokemons'
  end

  class TypeRelation < ActiveRecord::Base
    self.table_name = 'pokemon_type_relations'
  end

  class Evolution < ActiveRecord::Base
    self.table_name = 'pokemon_evolutions'
  end

  def up
    type_ids = select_rows('SELECT `key`, id FROM pokemon_types').to_h
    created = {}
    SPECIES.each do |attributes|
      species = create_species(attributes, created[attributes[:from]])
      created[attributes[:dex_id]] = species
      attributes[:types].each { |key| TypeRelation.create!(pokemon_id: species.id, pokemon_type_id: type_ids.fetch(key)) }
      attach_sprite(species, attributes[:sprite])
    end
  end

  def down
    ids = Species.where(dex_id: SPECIES.pluck(:dex_id)).ids
    raise ActiveRecord::IrreversibleMigration, 'Users own the new species' if owned?(ids)

    Evolution.where(from_id: ids).or(Evolution.where(to_id: ids)).delete_all
    TypeRelation.where(pokemon_id: ids).delete_all
    ActiveStorage::Attachment.where(record_type: 'Pokemon', record_id: ids).find_each(&:purge)
    Species.where(id: ids).update_all(ancestor_id: nil, descendant_id: nil)
    Species.where(id: ids).delete_all
  end

  private

  def create_species(attributes, from)
    species = Species.create!(**attributes.slice(:dex_id, :name, :slug, :rarity, :base_hp, :base_attack),
                              wild: from.nil?, line_root_id: from&.line_root_id || 0, descendant_level: 0)
    root_id = from&.line_root_id || species.id
    species.update!(line_root_id: root_id, ancestor_id: root_id, descendant_id: species.id)
    if from
      Evolution.create!(from_id: from.id, to_id: species.id, min_level: EEVEE_LEVEL,
                        characters: attributes[:characters])
    end
    species
  end

  def attach_sprite(species, filename)
    blob = ActiveStorage::Blob.create_and_upload!(io: SPRITES.join(filename).open, filename:,
                                                  content_type: 'image/gif')
    blob.analyze
    ActiveStorage::Attachment.create!(name: 'sprite', record_type: 'Pokemon', record_id: species.id, blob:)
  end

  def owned?(ids)
    select_value("SELECT 1 FROM user_pokemons WHERE pokemon_id IN (#{ids.join(', ').presence || 'NULL'}) LIMIT 1")
  end
end
