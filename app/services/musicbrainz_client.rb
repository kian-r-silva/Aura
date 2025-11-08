require 'json'

class MusicbrainzClient
  API = 'https://musicbrainz.org/ws/2'.freeze

  def self.search_recordings(query, limit: 10, contact_email: nil)
    return [] unless query.present?
    Rails.logger.debug "[MusicbrainzClient#search_recordings] query=#{query.inspect} limit=#{limit}"

    conn = Faraday.new(url: API) do |f|
      f.request :url_encoded
      f.options.timeout = 10
      f.options.open_timeout = 5
      f.adapter Faraday.default_adapter
    end

    user_agent = ENV['MUSICBRAINZ_USER_AGENT'] || "AuraApp/1.0 (#{contact_email || 'kian.r.silva@columbia.edu'})"

    resp = conn.get('recording', { query: query, fmt: 'json', limit: limit }) do |req|
      req.headers['User-Agent'] = user_agent
      req.headers['Accept'] = 'application/json'
    end

    Rails.logger.debug "[MusicbrainzClient#search_recordings] url=#{resp.env.url} status=#{resp.status}"

    return [] unless resp.status == 200

    body = JSON.parse(resp.body)
    (body['recordings'] || []).map do |rec|
      artists = (rec['artist-credit'] || []).map { |ac| ac.dig('artist', 'name') || ac['name'] }
      release = (rec['releases'] || []).first || {}

      {
        id: rec['id'],
        title: rec['title'],
        artists: artists.compact.join(', '),
        release: release['title'],
        release_id: release['id'],
        release_date: release['date']
      }
    end
  rescue StandardError => e
    Rails.logger.warn("[MusicbrainzClient#search_recordings] #{e.class}: #{e.message}")
    []
  end
end
