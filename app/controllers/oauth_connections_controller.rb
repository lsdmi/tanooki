# frozen_string_literal: true

# Studio: disconnect an OAuth client from the signed-in member only.
class OauthConnectionsController < ApplicationController
  before_action :authenticate_user!

  def destroy
    application = Doorkeeper::Application.find_by!(uid: params.expect(:id))
    Doorkeeper::AccessToken.revoke_all_for(application.id, current_user)
    Doorkeeper::AccessGrant.revoke_all_for(application.id, current_user)
    redirect_to studio_index_path(tab: 'teams'), notice: t('oauth_connections.revoked')
  end
end
