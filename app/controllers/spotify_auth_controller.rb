class SpotifyAuthController < ApplicationController
  before_action :require_login

  def callback
    auth = request.env['omniauth.auth']

    # Debug: log session and state to help diagnose CSRF/session mismatches during local dev
    Rails.logger.debug "[SpotifyAuth] session keys: #{session.keys.inspect}"
    Rails.logger.debug "[SpotifyAuth] session['omniauth.state'] = #{session['omniauth.state'].inspect}"
    Rails.logger.debug "[SpotifyAuth] params['state'] = #{params['state'].inspect}"
    Rails.logger.debug "[SpotifyAuth] auth present? #{!!auth} ; uid=#{auth&.dig('uid').inspect}"

    unless auth
      Rails.logger.warn "[SpotifyAuth] callback missing omniauth.auth payload"
      return redirect_to root_path, alert: 'Spotify auth failed'
    end

    current_user.connect_spotify_from_auth(auth)
    redirect_to root_path, notice: 'Spotify account connected'
  end

  def failure
    redirect_to root_path, alert: "Spotify auth error: #{params[:message] || 'unknown'}"
  end

  def disconnect
    current_user.disconnect_spotify!
    redirect_to root_path, notice: 'Spotify disconnected'
  end
end