# frozen_string_literal: true

class BattleLogger
  include Rails.application.routes.url_helpers

  attr_reader :attacker_id, :defender_id, :service

  def initialize(attacker_id, defender_id, service = nil)
    @attacker_id = attacker_id
    @defender_id = defender_id
    @service = service
    default_url_options[:host] = Rails.env.production? ? 'baka.in.ua' : 'localhost:3000'
  end

  def start
    render_partial('battles/logger_start', attacker_name: attacker_name, defender_name: defender_name)
  end

  def append_outcome(attacker, defender, outcome)
    round_number = service&.outcome_blocks&.size.to_i + 1
    outcome_html = render_partial(
      'battles/logger_outcome',
      attacker: attacker,
      defender: defender,
      outcome: outcome,
      round_number: round_number
    )
    service&.append_log(outcome_html)
  end

  def conclusion(outcome)
    render_partial(
      'battles/logger_conclusion',
      winner_name: winner_name(outcome),
      loser_name: loser_name(outcome)
    )
  end

  private

  def attacker_name
    @attacker_name ||= User.find(attacker_id).name
  end

  def defender_name
    @defender_name ||= User.find(defender_id).name
  end

  def loser_name(victory)
    victory == :victory ? defender_name : attacker_name
  end

  def winner_name(victory)
    victory == :victory ? attacker_name : defender_name
  end

  def render_partial(partial, locals = {})
    ApplicationController.render(
      partial: partial,
      locals: locals
    )
  end
end
