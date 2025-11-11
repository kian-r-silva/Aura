class User < ApplicationRecord
  has_secure_password

  has_many :reviews, dependent: :destroy

  validates :email, presence: true, uniqueness: true
  validates :name, presence: true
  validates :username, presence: true, uniqueness: true

  # Called from the OmniAuth callback
  def connect_spotify_from_auth(auth)
    uid = auth['uid']
    creds = auth['credentials'] || {}

    # If another user already has this spotify_uid, unlink them first so the
    # unique index doesn't raise at the DB level.
    ApplicationRecord.transaction do
      if uid.present?
        existing = User.find_by(spotify_uid: uid)
        if existing && existing != self
          existing.update!(spotify_uid: nil,
                           spotify_access_token: nil,
                           spotify_refresh_token: nil,
                           spotify_token_expires_at: nil,
                           spotify_connected: false)
        end
        self.spotify_uid = uid
      end

      self.spotify_access_token = creds['token']
      self.spotify_refresh_token = creds['refresh_token'] if creds['refresh_token'].present?
      self.spotify_token_expires_at = Time.current + creds['expires_in'].to_i.seconds if creds['expires_in']
      self.spotify_connected = true

      save!(validate: false)
    end
  rescue ActiveRecord::RecordNotUnique
    conflicting = User.find_by(spotify_uid: uid)
    if conflicting && conflicting != self
      conflicting.update!(spotify_uid: nil,
                          spotify_access_token: nil,
                          spotify_refresh_token: nil,
                          spotify_token_expires_at: nil,
                          spotify_connected: false)
      retry
    end
    false
  rescue StandardError => e
    Rails.logger.warn("[User#connect_spotify_from_auth] #{e.class}: #{e.message}")
    false
  end

  def disconnect_spotify!
    update(
      spotify_uid: nil,
      spotify_access_token: nil,
      spotify_refresh_token: nil,
      spotify_token_expires_at: nil,
      spotify_connected: false
    )
  end

  # Ensure token is valid; refresh if expired. Returns an access token string or nil.
  def spotify_access_token_with_refresh!
    return spotify_access_token if spotify_access_token.present? && spotify_token_expires_at.present? && spotify_token_expires_at > 30.seconds.from_now

    # need to refresh
    return nil unless spotify_refresh_token.present?

    token = refresh_spotify_token!
    update(spotify_access_token: token[:access_token], spotify_token_expires_at: Time.current + token[:expires_in].to_i.seconds) if token
    token ? token[:access_token] : nil
  end

  private

  def refresh_spotify_token!
    client_id = ENV['SPOTIFY_CLIENT_ID']
    client_secret = ENV['SPOTIFY_CLIENT_SECRET']
    return nil unless client_id && client_secret && spotify_refresh_token

    uri = URI('https://accounts.spotify.com/api/token')
    req = Net::HTTP::Post.new(uri)
    req.basic_auth(client_id, client_secret)
    req.set_form_data('grant_type' => 'refresh_token', 'refresh_token' => spotify_refresh_token)

    res = Net::HTTP.start(uri.hostname, uri.port, use_ssl: true) { |http| http.request(req) }
    return nil unless res.is_a?(Net::HTTPSuccess)

    JSON.parse(res.body).symbolize_keys
  rescue StandardError
    nil
  end
end
