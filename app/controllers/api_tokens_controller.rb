# frozen_string_literal: true

# Studio: create and revoke personal API tokens. The secret is returned once, in the flash.
class ApiTokensController < ApplicationController
  EXPIRY_DAYS = { '30' => 30, '90' => 90, '365' => 365 }.freeze

  before_action :authenticate_user!

  def create
    token = ApiToken.issue!(
      user: current_user, name: token_params[:name], scopes: token_params[:scopes], expires_at: expiry_from_params
    )
    redirect_to studio_index_path(tab: 'teams'), flash: { api_token_secret: token.secret }
  rescue ActiveRecord::RecordInvalid => e
    redirect_to studio_index_path(tab: 'teams'), alert: e.record.errors.full_messages.to_sentence
  end

  def destroy
    current_user.api_tokens.find(params.expect(:id)).revoke!
    redirect_to studio_index_path(tab: 'teams'), notice: t('api_tokens.revoked')
  end

  private

  def token_params
    params.expect(api_token: [:name, :expires_in, { scopes: [] }])
  end

  def expiry_from_params
    EXPIRY_DAYS.fetch(token_params[:expires_in].to_s, 90).days.from_now
  end
end
