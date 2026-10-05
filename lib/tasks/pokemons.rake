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

  desc 'Simulate N battles per measure for one engine version, or every version side by side: the balance gates, ' \
       'then the last version in detail'
  task :simulate, %i[battles seed version] => :environment do |_task, args|
    battles = Integer(args[:battles] || 1000)
    seed = Integer(args[:seed] || 2026)
    versions = args[:version] ? [Integer(args[:version])] : Pokemons::Engine::VERSIONS
    unless (versions - Pokemons::Engine::VERSIONS).empty?
      abort "Unknown engine version #{args[:version]}; known: #{Pokemons::Engine::VERSIONS.join(', ')}"
    end

    species = Pokemons::BalanceReport::Species.catalogue
    trainers = Pokemons::BalanceReport::Trainers.load(species)
    reports = versions.map do |version|
      Pokemons::BalanceReport.new(battles:, seed:, version:, species:, trainers:)
    end
    puts Pokemons::BalanceReport::Markdown.render(reports)
  end
end
