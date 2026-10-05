# frozen_string_literal: true

namespace :pokemons do
  desc "Rewrite config/pokemon_might.yml, each species' one-on-one win rate against the rest (the card's «Могуть»); " \
       'run after changing the version 2 balance or the species'
  task :might, %i[repeats seed] => :environment do |_task, args|
    species = Pokemons::BalanceReport::Species.catalogue
    field = Pokemons::BalanceReport::Field.new(species:, repeats: Integer(args[:repeats] || 20),
                                               seed: Integer(args[:seed] || 2026))
    rows = field.rates.sort.map { |dex_id, rate| "#{dex_id}: #{rate.round(3)}" }
    header = "# Written by bin/rails pokemons:might (#{species.size} species, engine version " \
             "#{Pokemons::Engine::VERSION}): one-on-one win rate against the rest, by dex number. Pokemons::StatTiers."
    Pokemons::StatTiers::PATH.write([header, *rows, ''].join("\n"))
    puts "#{rows.size} species written to #{Pokemons::StatTiers::PATH.relative_path_from(Rails.root)}"
  end
end
