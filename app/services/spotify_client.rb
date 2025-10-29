require 'base64'
require 'json'

class SpotifyClient
  SPOTIFY_API = 'https://api.spotify.com'
  TOKEN_URL = 'https://accounts.spotify.com/api/token'

  def initialize(user)
    @user = user
  end

  # returns array of track hashes: {id, name, artists, album, image, played_at, external_url}
  def recent_tracks(limit: 25)
    resp = api_get('/v1/me/player/recently-played', { limit: limit })
    return [] unless resp && resp.status == 200

    body = JSON.parse(resp.body)
    (body['items'] || []).map do |item|
      track = item['track'] || {}
      {
        id: track['id'],
        name: track['name'],
        artists: (track['artists'] || []).map { |a| a['name'] }.join(', '),
        album: track.dig('album', 'name'),
        image: track.dig('album', 'images', 0, 'url'),
        played_at: item['played_at'],
        external_url: track.dig('external_urls', 'spotify')
      }
    end
  rescue StandardError => e
    Rails.logger.error("[SpotifyClient#recent_tracks] #{e.class}: #{e.message}")
    []
  end

  # Search tracks by query string. Returns array similar to recent_tracks.
  def search_tracks(query, limit: 10)
    return [] unless query.present?

    resp = api_get('/v1/search', { q: query, type: 'track', limit: limit })
    return [] unless resp && resp.status == 200

    body = JSON.parse(resp.body)
    items = body.dig('tracks', 'items') || []
    items.map do |track|
      {
        id: track['id'],
        name: track['name'],
        artists: (track['artists'] || []).map { |a| a['name'] }.join(', '),
        album: track.dig('album', 'name'),
        image: track.dig('album', 'images', 0, 'url'),
        external_url: track.dig('external_urls', 'spotify')
      }
    end
  rescue StandardError => e
    Rails.logger.error("[SpotifyClient#search_tracks] #{e.class}: #{e.message}")
    []
  end

  private

  def api_get(path, params = {})
    conn = Faraday.new(url: SPOTIFY_API) do |f|
      f.request :url_encoded
      f.adapter Faraday.default_adapter
    end

    resp = conn.get(path, params) do |req|
      req.headers['Authorization'] = "Bearer #{@user.spotify_access_token}"
      req.headers['Accept'] = 'application/json'
    end

    if resp.status == 401 && @user.spotify_refresh_token.present?
      if refresh_token!
        resp = conn.get(path, params) do |req|
          req.headers['Authorization'] = "Bearer #{@user.spotify_access_token}"
          req.headers['Accept'] = 'application/json'
        end
      end
    end

    if resp && resp.status != 200
      Rails.logger.warn("[SpotifyClient#api_get] non-200 response status=#{resp.status} body=#{resp.body}")
    end
    resp
  rescue StandardError => e
    Rails.logger.error("[SpotifyClient#api_get] #{e.class}: #{e.message}")
    nil
  end

  def refresh_token!
    client_id = ENV['SPOTIFY_CLIENT_ID']
    client_secret = ENV['SPOTIFY_CLIENT_SECRET']
    return false unless client_id && client_secret && @user.spotify_refresh_token

    conn = Faraday.new(url: TOKEN_URL) do |f|
      f.request :url_encoded
      f.adapter Faraday.default_adapter
    end

    resp = conn.post do |req|
      req.headers['Authorization'] = "Basic #{Base64.strict_encode64("#{client_id}:#{client_secret}") }"
      req.body = { grant_type: 'refresh_token', refresh_token: @user.spotify_refresh_token }
    end

    return false unless resp.status == 200

    data = JSON.parse(resp.body)
    expires_at = if data['expires_in']
                   Time.current + data['expires_in'].to_i.seconds
                 else
                   nil
                 end
    @user.update(
      spotify_access_token: data['access_token'],
      spotify_token_expires_at: expires_at
    )
    true
  rescue StandardError => e
    Rails.logger.warn("[SpotifyClient#refresh_token!] #{e.class}: #{e.message}")
    false
  end
end
