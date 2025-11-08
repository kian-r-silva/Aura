class SpotifyController < ApplicationController
  before_action :require_login

  def recent
    unless current_user.spotify_connected
      redirect_to root_path, alert: 'Connect your Spotify account first.'
      return
    end

    client = SpotifyClient.new(current_user)
    @tracks = client.recent_tracks(limit: 25)
  rescue => e
    Rails.logger.error("[SpotifyController#recent] #{e.class}: #{e.message}")
    @tracks = []
    flash.now[:alert] = 'Could not load recent tracks from Spotify.'
  end

  # Search page - shows a search box and results when q is present
  def search
    unless current_user.spotify_connected
      redirect_to root_path, alert: 'Connect your Spotify account first.'
      return
    end

    @query = params[:q]&.to_s
    @tracks = []
    if @query.present?
      client = SpotifyClient.new(current_user)
      @tracks = client.search_tracks(@query, limit: 25)
    end
  rescue => e
    Rails.logger.error("[SpotifyController#search] #{e.class}: #{e.message}")
    @tracks = []
    flash.now[:alert] = 'Could not search Spotify.'
  end

  # existing my_tracks helper left for convenience (optional)
  def my_tracks
    token = current_user.spotify_access_token_with_refresh!
    return redirect_to root_path, alert: 'Spotify not connected' unless token

    uri = URI('https://api.spotify.com/v1/me/tracks?limit=20')
    req = Net::HTTP::Get.new(uri)
    req['Authorization'] = "Bearer #{token}"

    res = Net::HTTP.start(uri.hostname, uri.port, use_ssl: true) { |http| http.request(req) }
    @items = res.is_a?(Net::HTTPSuccess) ? JSON.parse(res.body)['items'] : []
  rescue StandardError => e
    Rails.logger.error("Spotify API error: #{e.message}")
    @items = []
  ensure
    render plain: '' unless performed?
  end
end