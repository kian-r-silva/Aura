class LastfmAuthController < ApplicationController
  before_action :require_login

  def auth
    api_key = ENV['LASTFM_API_KEY']
    callback_url = ENV['LASTFM_CALLBACK_URL'] || lastfm_auth_callback_url(host: request.host_with_port, protocol: request.protocol)

    unless api_key
      redirect_to root_path, alert: 'Last.fm API not configured'
      return
    end

    auth_url = "http://www.last.fm/api/auth/?api_key=#{api_key}&cb=#{CGI.escape(callback_url)}"
    redirect_to auth_url, allow_other_host: true
  end

  def callback
    token = params[:token]

    unless token
      Rails.logger.warn "[LastfmAuth] callback missing token parameter"
      return redirect_to root_path, alert: 'Last.fm auth failed: no token received'
    end

    Rails.logger.info "[LastfmAuth] Received token: #{token[0..10]}..." if token

    session_data = LastfmClient.get_session(token)

    unless session_data
      Rails.logger.warn "[LastfmAuth] failed to get session for token. Check logs for details."
      return redirect_to root_path, alert: 'Last.fm auth failed: could not get session. Check server logs for details.'
    end

    current_user.connect_lastfm_from_session(session_data[:session_key], session_data[:username])
    redirect_to root_path, notice: 'Last.fm account connected'
  rescue => e
    Rails.logger.error("[LastfmAuth#callback] #{e.class}: #{e.message}")
    Rails.logger.error("[LastfmAuth#callback] Backtrace: #{e.backtrace.first(10).join("\n")}")
    redirect_to root_path, alert: 'Last.fm auth failed'
  end

  def disconnect
    current_user.disconnect_lastfm!
    redirect_to root_path, notice: 'Last.fm disconnected'
  end

  def token
    session_key = current_user.lastfm_session_key
    if session_key
      render json: { session_key: session_key }
    else
      render json: { error: 'no_session' }, status: :unauthorized
    end
  end
end

