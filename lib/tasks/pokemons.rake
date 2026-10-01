# frozen_string_literal: true

namespace :pokemons do
  desc 'List user Pokémon at or past their evolution level that never evolved (APPLY=1 to evolve them)'
  task evolve_overdue: :environment do
    apply = ENV['APPLY'].present?
    rows = Pokemons::OverdueEvolutions.call(apply:)
    rows.each do |row|
      puts "user_pokemon=#{row.user_pokemon_id} user=#{row.user_id} level=#{row.level} #{row.from} -> #{row.to}"
    end
    puts "#{rows.size} overdue; #{apply ? 'evolved' : 'dry run, nothing written (APPLY=1 to evolve)'}"
  end
end
