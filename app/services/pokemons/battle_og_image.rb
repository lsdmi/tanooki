# frozen_string_literal: true

module Pokemons
  # PNG for Open Graph: winner lead sprite left, loser lead right, on a quiet stone canvas.
  class BattleOgImage
    WIDTH = 1400
    HEIGHT = 700
    SPRITE = 420
    BACKGROUND = [245, 245, 244].freeze
    CACHE_VERSION = 1
    LEFT_X = (WIDTH * 0.28).round
    RIGHT_X = (WIDTH * 0.72).round
    MID_X = (WIDTH / 2).round
    MID_Y = (HEIGHT / 2).round

    def initialize(battle)
      @battle = battle
    end

    def png
      Rails.cache.fetch(cache_key, expires_in: 1.week) { render_png }
    end

    private

    attr_reader :battle

    def cache_key
      ['pokemon-battle-og', CACHE_VERSION, battle.id, battle.created_at.to_i]
    end

    def render_png
      require 'vips'
      place_all(blank_canvas).write_to_buffer('.png')
    end

    def blank_canvas
      rgb = (Vips::Image.black(WIDTH, HEIGHT, bands: 3) + BACKGROUND).cast(:uchar)
      rgb.copy(interpretation: :srgb).bandjoin(255)
    end

    def place_all(canvas)
      layers = [[sprite_for(:winner), LEFT_X], [sprite_for(:loser), RIGHT_X], [vs_mark, MID_X]]
      layers.reduce(canvas) { |acc, (image, x)| place(acc, image, x) }
    end

    def place(canvas, image, centre_x)
      return canvas unless image

      canvas.composite(rgba(image), :over, x: centre_x - (image.width / 2), y: MID_Y - (image.height / 2))
    end

    def sprite_for(role)
      species = lead_species(role)
      return unless species&.sprite&.attached?

      species.sprite.blob.open { |file| still_frame(file.path) }
    rescue StandardError
      nil
    end

    def still_frame(path)
      image = Vips::Image.new_from_file(path, n: 1, access: :sequential, fail_on: :error)
      rgba(image).thumbnail_image(SPRITE, height: SPRITE, size: :down)
    end

    def rgba(image)
      image = image.colourspace(:srgb) unless %i[srgb rgb].include?(image.interpretation)
      image = image.bandjoin(255) if image.bands == 3
      image = image.extract_band(0, n: 4) if image.bands > 4
      image
    end

    def vs_mark
      text = Vips::Image.text('VS', font: 'sans bold 72', align: :centre, rgba: true)
      text.gravity(:centre, text.width + 40, text.height + 24)
    rescue StandardError
      nil
    end

    def lead_species(role)
      side = role == :winner ? winner_side : loser_side
      pokemon_id = Array(battle.team(side)).first&.stringify_keys&.[]('pokemon_id')
      return if pokemon_id.blank?

      species_by_id[pokemon_id.to_i]
    end

    def winner_side
      battle.attacker_won? ? :attacker : :defender
    end

    def loser_side
      battle.attacker_won? ? :defender : :attacker
    end

    def species_by_id
      @species_by_id ||= begin
        ids = [winner_side, loser_side].filter_map do |side|
          Array(battle.team(side)).first&.stringify_keys&.[]('pokemon_id')
        end.map(&:to_i).uniq
        Pokemon.where(id: ids).includes(sprite_attachment: :blob).index_by(&:id)
      end
    end
  end
end
