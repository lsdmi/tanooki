# frozen_string_literal: true

# Spelling fixes for species names: "і" after consonants outside the rule of nine, sounds closer to the English
# pronunciation, lost "-нґ" endings and the apostrophe in М'яут. Slugs follow the new names; Нідоран ♂ gets its dex
# number instead of a UUID suffix.
class FixPokemonUkrainianNames < ActiveRecord::Migration[8.1]
  # dex_id => [[old name, old slug], [new name, new slug]]
  RENAMES = {
    16 => [%w[Пиджі pidzhy], %w[Піджі pidzhi]],
    17 => [%w[Пиджеото pidzheoto], %w[Піджеото pidzheoto]],
    18 => [%w[Пиджеот pidzheot], %w[Піджеот pidzheot]],
    24 => [%w[Ербок erbok], %w[Арбок arbok]],
    32 => [['Нідоран ♂', 'nidoran-7e139331-de04-41bd-bb25-88c75673db39'], ['Нідоран ♂', 'nidoran-32']],
    34 => [%w[Нідокинґ nidoking], %w[Нідокінґ nidoking]],
    37 => [%w[Вульпикс vulpiks], %w[Вульпікс vulpiks]],
    40 => [%w[Виґлітаф viglitaf], %w[Віґлітаф viglitaf]],
    42 => [%w[Ґолбат golbet], %w[Ґолбат golbat]],
    52 => [%w[Мяут miaut], %w[М'яут miaut]],
    58 => [%w[Ґровлит hrovlit], %w[Ґрауліт graulit]],
    61 => [%w[Полівирл polivirl], %w[Полівірл polivirl]],
    74 => [%w[Джіодюд dzhiodiud], %w[Джіодуд dzhiodud]],
    78 => [%w[Рапидаш rapidash], %w[Рапідаш rapidash]],
    79 => [%w[Словпок slovpok], %w[Слоупок sloupok]],
    80 => [%w[Словбро slovbro], %w[Слоубро sloubro]],
    83 => [%w[Фарфечд farfechd], %w[Фарфетчд farfetchd]],
    87 => [%w[Дюгон diuhon], %w[Дюґонґ diugong]],
    93 => [%w[Гантер hanter], %w[Гонтер honter]],
    95 => [%w[Оникс oniks], %w[Онікс oniks]],
    96 => [%w[Дровзі drovzi], %w[Драузі drauzi]],
    99 => [%w[Кинґлер kingler], %w[Кінґлер kingler]],
    102 => [%w[Екзекют ekzekiut], %w[Екзеґкют ekzegkiut]],
    106 => [%w[Гитмонлі hitmonli], %w[Гітмонлі hitmonli]],
    107 => [%w[Гитмончен hitmonchen], %w[Гітмончен hitmonchen]],
    108 => [%w[Ликитон lykyton], %w[Лікітанґ likitang]],
    109 => [%w[Кафин kafin], %w[Кофінґ kofing]],
    110 => [%w[Візин vizin], %w[Візинґ vizyng]],
    127 => [%w[Пинсир pinsir], %w[Пінсир pinsyr]]
  }.freeze

  def up
    RENAMES.each { |dex_id, (_old, (name, slug))| rename(dex_id, name, slug) }
  end

  def down
    RENAMES.each { |dex_id, ((name, slug), _new)| rename(dex_id, name, slug) }
  end

  private

  def rename(dex_id, name, slug)
    execute <<~SQL.squish
      UPDATE pokemons SET name = #{connection.quote(name)}, slug = #{connection.quote(slug)}
      WHERE dex_id = #{Integer(dex_id)}
    SQL
  end
end
