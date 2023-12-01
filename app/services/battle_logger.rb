# frozen_string_literal: true

class BattleLogger
  include Rails.application.routes.url_helpers

  attr_reader :attacker_id, :defender_id

  def initialize(attacker_id, defender_id)
    @attacker_id = attacker_id
    @defender_id = defender_id

    default_url_options[:host] = Rails.env.production? ? 'baka.in.ua' : 'localhost:3000'
  end

  def start
    start_message
  end

  def outcome(attacker, defender, outcome)
    outcome_message(attacker, defender, outcome)
  end

  def conclusion(outcome)
    conclusion_message(outcome)
  end

  private

  def attacker_name
    @attacker_name ||= User.find(attacker_id).name
  end

  def defender_name
    @defender_name ||= User.find(defender_id).name
  end

  def outcome_message(attacker, defender, outcome)
    ActionController::Base.helpers.sanitize(
      "<div class='flex justify-center text-center'>
        <div class='mb-4 grid grid-cols-3 gap-2'>
          <div class='flex flex-col items-center justify-center text-center'>
            <div class='flex items-center justify-center h-8 w-14 border-2 shadow-md rounded-full mb-1'>
              <img src='#{url_for(attacker.pokemon.sprite)}'
                    alt='#{attacker.pokemon.sprite.blob.filename}'
                    class='w-auto cursor-pointer rounded-lg transform transition duration-500 hover:scale-110'>
            </div>
          </div>

          <div class='flex flex-col items-center justify-center text-center'>
            <span class='font-light text-gray-600'>#{outcome == :victory ? 'перемагає' : 'програє'}</span>
          </div>

          <div class='flex flex-col items-center justify-center text-center'>
            <div class='flex items-center justify-center h-8 w-14 border-2 shadow-md rounded-full mb-1'>
            <img src='#{url_for(defender.pokemon.sprite)}'
                  alt='#{defender.pokemon.sprite.blob.filename}'
                  class='w-auto cursor-pointer rounded-lg transform transition duration-500 hover:scale-110'>
            </div>
          </div>
        </div>
      </div"
    )
  end

  def start_message
    ActionController::Base.helpers.sanitize(
      "<div class='mb-4 font-light inline-block'>Вітаємо вас на Арені, шанові глядачі! Сьогодні " \
      'ми станемо свідками неймовірного ' \
      "протистояння між <span class='font-bold'>#{attacker_name}</span> та " \
      "<span class='font-bold'>#{defender_name}</span>!</div>" \
    )
  end

  def conclusion_message(outcome)
    ActionController::Base.helpers.sanitize(
      "<div class='mt-4 font-light inline-block'>
        І-і... все! Останній покемон
        <span class='font-bold'>#{loser_name(outcome)}</span> падає без сил, тож
        <span class='font-bold'>#{winner_name(outcome)}</span> святкує перемогу в цьому бою!
      </div>"
    )
  end

  def loser_name(victory)
    victory == :victory ? defender_name : attacker_name
  end

  def winner_name(victory)
    victory == :victory ? attacker_name : defender_name
  end
end
