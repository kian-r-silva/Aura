class User < ApplicationRecord
  has_secure_password

  has_many :reviews, dependent: :destroy
  has_many :follows_as_follower, class_name: 'Follow', foreign_key: 'follower_id', dependent: :destroy
  has_many :follows_as_following, class_name: 'Follow', foreign_key: 'following_id', dependent: :destroy
  has_many :following, through: :follows_as_follower, source: :following
  has_many :followers, through: :follows_as_following, source: :follower

  validates :email, presence: true, uniqueness: true
  validates :name, presence: true
  validates :username, presence: true, uniqueness: true

  # Follow/unfollow helper methods
  def follow(other_user)
    following << other_user unless following.include?(other_user)
  end

  def unfollow(other_user)
    following.delete(other_user)
  end

  def following?(other_user)
    following.include?(other_user)
  end

  # Called from the OmniAuth callback
  def connect_spotify_from_auth(auth)
    uid = auth['uid']
    creds = auth['credentials'] || {}

    ApplicationRecord.transaction do
      if uid.present?
        User.where(spotify_uid: uid).where.not(id: id).update_all(
          spotify_uid: nil,
          spotify_access_token: nil,
          spotify_refresh_token: nil,
          spotify_token_expires_at: nil,
          spotify_connected: false,
          updated_at: Time.current
        )

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

  # Called from Last.fm auth callback
  def connect_lastfm_from_session(session_key, username)
    ApplicationRecord.transaction do
      if username.present?
        User.where(lastfm_username: username).where.not(id: id).update_all(
          lastfm_username: nil,
          lastfm_session_key: nil,
          lastfm_connected: false,
          updated_at: Time.current
        )

        self.lastfm_username = username
      end

      self.lastfm_session_key = session_key
      self.lastfm_connected = true

      save!(validate: false)
    end
  rescue ActiveRecord::RecordNotUnique
    conflicting = User.find_by(lastfm_username: username)
    if conflicting && conflicting != self
      conflicting.update!(
        lastfm_username: nil,
        lastfm_session_key: nil,
        lastfm_connected: false
      )
      retry
    end
    false
  rescue StandardError => e
    Rails.logger.warn("[User#connect_lastfm_from_session] #{e.class}: #{e.message}")
    false
  end

  def disconnect_lastfm!
    update(
      lastfm_username: nil,
      lastfm_session_key: nil,
      lastfm_connected: false
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
