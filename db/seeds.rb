# frozen_string_literal: true

# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).
#
# Examples:
#
#   movies = Movie.create([{ name: "Star Wars" }, { name: "Lord of the Rings" }])
#   Character.create(name: "Luke", movie: movies.first)

# Every time we need to reset a clean development data,
# we can run the bin/rails db:seed command
puts "\n== Seeding the database with fixtures =="
fixtures = %w[users publications advertisements active_storage_blobs active_storage_attachments action_text_rich_texts]
fixtures.each { |fixture| system("bin/rails db:fixtures:load FIXTURES=#{fixture}") }
