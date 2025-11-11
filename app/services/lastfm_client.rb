require 'digest/md5'
require 'json'
require 'uri'

class LastfmClient
  LASTFM_API = 'http://ws.audioscrobbler.com/2.0/'

  def initialize(user = nil)
    @user = user
  end

  # Exchange authentication token for session key
  # Returns hash with :session_key and :username, or nil on failure
  def self.get_session(token)
    api_key = ENV['LASTFM_API_KEY']
    shared_secret = ENV['LASTFM_SHARED_SECRET']
    return nil unless api_key && shared_secret && token

    params = {
      'method' => 'auth.getSession',
      'api_key' => api_key,
      'token' => token,
      'format' => 'json'
    }

    signature = self.generate_signature(params, shared_secret)
    params['api_sig'] = signature

    uri = URI(LASTFM_API)
    uri.query = URI.encode_www_form(params)

    resp = Faraday.get(uri.to_s)
    return nil unless resp.status == 200

    body = JSON.parse(resp.body)
    return nil if body['error']

    session_data = body.dig('session')
    return nil unless session_data

    {
      session_key: session_data['key'],
      username: session_data['name']
    }
  rescue StandardError => e
    Rails.logger.error("[LastfmClient.get_session] #{e.class}: #{e.message}")
    nil
  end

  # Returns array of track hashes: {id, name, artists, album, image, played_at, external_url}
  def recent_tracks(limit: 25)
    return [] unless @user&.lastfm_session_key.present?

    params = {
      'method' => 'user.getRecentTracks',
      'user' => @user.lastfm_username,
      'api_key' => ENV['LASTFM_API_KEY'],
      'limit' => limit.to_s,
      'format' => 'json'
    }

    resp = api_call(params, authenticated: true)
    return [] unless resp && resp['recenttracks']

    tracks = resp.dig('recenttracks', 'track') || []
    tracks = [tracks] unless tracks.is_a?(Array) # Handle single track response

    tracks.map do |track|
      {
        id: track.dig('mbid') || track.dig('@attr', 'nowplaying') ? 'nowplaying' : nil,
        name: track['name'],
        artists: track.dig('artist', '#text') || track.dig('artist', 'name') || '',
        album: track.dig('album', '#text') || track.dig('album', 'name') || '',
        image: extract_image_url(track['image']),
        played_at: track.dig('date', '#text') || track.dig('@attr', 'date') || nil,
        external_url: track['url'] || "https://www.last.fm/music/#{URI.encode_www_form_component(track.dig('artist', '#text') || '')}/_/#{URI.encode_www_form_component(track['name'] || '')}"
      }
    end
  rescue StandardError => e
    Rails.logger.error("[LastfmClient#recent_tracks] #{e.class}: #{e.message}")
    []
  end

  # Search tracks by query string. Returns array similar to recent_tracks.
  def search_tracks(query, limit: 10)
    return [] unless query.present?

    params = {
      'method' => 'track.search',
      'track' => query,
      'api_key' => ENV['LASTFM_API_KEY'],
      'limit' => limit.to_s,
      'format' => 'json'
    }

    resp = api_call(params, authenticated: false)
    return [] unless resp && resp['results']

    tracks = resp.dig('results', 'trackmatches', 'track') || []
    tracks = [tracks] unless tracks.is_a?(Array)

    tracks.map do |track|
      {
        id: track['mbid'] || nil,
        name: track['name'],
        artists: track['artist'] || '',
        album: track.dig('album', '#text') || track.dig('album', 'name') || '',
        image: extract_image_url(track['image']),
        external_url: track['url'] || "https://www.last.fm/music/#{URI.encode_www_form_component(track['artist'] || '')}/_/#{URI.encode_www_form_component(track['name'] || '')}"
      }
    end
  rescue StandardError => e
    Rails.logger.error("[LastfmClient#search_tracks] #{e.class}: #{e.message}")
    []
  end

  private

  def api_call(params, authenticated: false)
    shared_secret = ENV['LASTFM_SHARED_SECRET']
    return nil unless ENV['LASTFM_API_KEY']

    params['api_key'] ||= ENV['LASTFM_API_KEY']
    params['format'] ||= 'json'

    if authenticated
      return nil unless @user&.lastfm_session_key.present? && shared_secret
      params['sk'] = @user.lastfm_session_key
      # Generate signature from params (excluding api_sig itself)
      params['api_sig'] = generate_signature(params, shared_secret)
    end

    uri = URI(LASTFM_API)
    uri.query = URI.encode_www_form(params)

    resp = Faraday.get(uri.to_s)
    return nil unless resp.status == 200

    body = JSON.parse(resp.body)
    return nil if body['error']

    body
  rescue StandardError => e
    Rails.logger.error("[LastfmClient#api_call] #{e.class}: #{e.message}")
    nil
  end

  def self.generate_signature(params, shared_secret)
    # Order parameters alphabetically and concatenate as namevalue pairs
    sorted_params = params.sort_by { |k, _v| k.to_s }
    signature_string = sorted_params.map { |k, v| "#{k}#{v}" }.join
    signature_string += shared_secret

    Digest::MD5.hexdigest(signature_string)
  end

  def generate_signature(params, shared_secret)
    self.class.generate_signature(params, shared_secret)
  end

  def extract_image_url(images)
    return nil unless images

    # Last.fm returns array of images with size attributes
    if images.is_a?(Array)
      # Find largest image (usually last in array, or look for 'extralarge'/'large')
      large_image = images.find { |img| img['size'] == 'extralarge' } ||
                    images.find { |img| img['size'] == 'large' } ||
                    images.last
      large_image&.dig('#text') || large_image&.dig('content')
    elsif images.is_a?(Hash)
      images['#text'] || images['content'] || images['extralarge'] || images['large']
    else
      images.to_s
    end
  end
end

