class AnalyticsService
  def initialize(user = nil)
    @user = user
    @lastfm_client = LastfmClient.new(user)
  end

  def lastfm_top_artists(limit: 5, lookback: 100)
    return [] unless @user&.lastfm_connected

    tracks = @lastfm_client.recent_tracks(limit: lookback)
    counts = Hash.new(0)
    tracks.each { |t| counts[t[:artists]] += 1 if t[:artists].present? }
    counts.sort_by { |_, v| -v }.first(limit).map { |artist, plays| { artist: artist, plays: plays } }
  end

  def lastfm_top_tracks(limit: 5, lookback: 100)
    return [] unless @user&.lastfm_connected

    tracks = @lastfm_client.recent_tracks(limit: lookback)
    counts = Hash.new(0)
    tracks.each do |t|
      key = "#{t[:name]} — #{t[:artists]}"
      counts[key] += 1 if t[:name].present?
    end
    counts.sort_by { |_, v| -v }.first(limit).map do |k, plays|
      name, artist = k.split(' — ', 2)
      { track: name, artist: artist, plays: plays }
    end
  end

  def aura_top_rated_songs(limit: 5)
    Song.joins(:reviews)
        .select('songs.*, AVG(reviews.rating) AS avg_rating')
        .group('songs.id')
        .order('avg_rating DESC')
        .limit(limit)
  end

  def user_top_rated_songs(limit: 5)
    return [] unless @user
    Song.joins(:reviews)
        .where(reviews: { user_id: @user.id })
        .select('songs.*, AVG(reviews.rating) AS avg_rating')
        .group('songs.id')
        .order('avg_rating DESC')
        .limit(limit)
  end

  def recommendations_for_user(limit: 5)
    return aura_fallback_recommendations(limit) unless @user

    artist_list = lastfm_top_artists(limit: 10, lookback: 200).map { |h| h[:artist] }
    return aura_fallback_recommendations(limit) if artist_list.empty?

    reviewed_song_ids = @user.reviews.pluck(:song_id)

    candidates = Song.where(artist: artist_list).where.not(id: reviewed_song_ids)
                     .left_joins(:reviews)
                     .select('songs.*, AVG(reviews.rating) AS avg_rating')
                     .group('songs.id')
                     .order(Arel.sql('avg_rating DESC NULLS LAST'))
                     .limit(limit)

    results = candidates.to_a
    return aura_fallback_recommendations(limit) if results.empty?
    results
  end

  def recommendations_for_song(song, user = nil, limit: 5)
    return [] unless song

    recs = Song.where(artist: song.artist).where.not(id: song.id)
               .joins('LEFT JOIN reviews ON reviews.song_id = songs.id')
               .select('songs.*, AVG(reviews.rating) AS avg_rating')
               .group('songs.id')
               .order('avg_rating DESC NULLS LAST')
               .limit(limit)

    if recs.blank? && user
      recs = AnalyticsService.new(user).recommendations_for_user(limit: limit)
    end

    recs
  end

  private

  def aura_fallback_recommendations(limit)
    aura_top_rated_songs(limit: limit)
  end
end
