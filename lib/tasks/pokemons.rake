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

  desc 'Simulate N battles per table between random teams of real species: win rates by trait, type, rarity, power'
  task :simulate, %i[battles seed] => :environment do |_task, args|
    report = Pokemons::BalanceReport.new(battles: Integer(args[:battles] || 1000), seed: Integer(args[:seed] || 2026))
    puts Pokemons::BalanceReport::Markdown.render(report)
  end

  desc 'Delete the Action Text bodies of legacy battle logs in batches (BATCH=500, PAUSE=1 seconds, DRY_RUN=1 to count)'
  task purge_legacy_logs: :environment do
    purge = Pokemons::LegacyBattleLogPurge.new(batch_size: Integer(ENV.fetch('BATCH', 500)),
                                               pause: Float(ENV.fetch('PAUSE', 1)))
    puts "bodies=#{purge.remaining} unconverted_logs=#{purge.unconverted}"
    next if ENV['DRY_RUN'].present?

    total = purge.call { |deleted| puts "deleted=#{deleted}" }
    puts "done: deleted=#{total} bodies=#{purge.remaining}"
  end
end
