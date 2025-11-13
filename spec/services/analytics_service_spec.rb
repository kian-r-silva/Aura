require 'rails_helper'

RSpec.describe AnalyticsService, type: :service do
  describe '#recommendations_for_user' do
    let(:user) { create(:user) }

    before do
      user.update!(lastfm_connected: true)
      allow_any_instance_of(LastfmClient).to receive(:track_similar).and_return([
        { name: 'Paranoid Android', artist: 'Radiohead', url: 'http://last.fm/p1' },
        { name: 'Unknown Track', artist: 'Some Artist', url: 'http://last.fm/p2' }
      ])

      allow_any_instance_of(LastfmClient).to receive(:recent_tracks).and_return([
        { name: 'Karma Police', artists: 'Radiohead', album: '', image: nil }
      ])
    end

    it 'returns Last.fm entries when no local match exists' do
      service = AnalyticsService.new(user)
      recs = service.recommendations_for_user(limit: 5)

      expect(recs).to be_an(Array)
      expect(recs.first).to be_a(Hash)
      expect(recs.first[:name]).to eq('Paranoid Android')
      expect(recs.first[:artist]).to eq('Radiohead')
    end

    it 'maps to local songs when available' do
      song = create(:song, title: 'Paranoid Android', artist: 'Radiohead')

      service = AnalyticsService.new(user)
      recs = service.recommendations_for_user(limit: 5)

      expect(recs.any? { |r| r.is_a?(Song) && r.id == song.id }).to be true
    end
  end

  describe '#lastfm_top_artists and #lastfm_top_tracks' do
    let(:user) { create(:user) }

    before do
      user.update!(lastfm_connected: true)
    end

    it 'returns top artists with play counts' do
      allow_any_instance_of(LastfmClient).to receive(:recent_tracks).and_return([
        { name: 'Karma Police', artists: 'Radiohead', album: '', image: nil },
        { name: 'Paranoid Android', artists: 'Radiohead', album: '', image: nil },
        { name: 'Come Together', artists: 'The Beatles', album: '', image: nil }
      ])

      service = AnalyticsService.new(user)
      artists = service.lastfm_top_artists(limit: 2, lookback: 50)

      expect(artists).to be_an(Array)
      expect(artists.first[:artist]).to eq('Radiohead')
      expect(artists.first[:plays]).to eq(2)
      expect(artists.map { |a| a[:artist] }).to include('The Beatles')
    end

    it 'returns top tracks with play counts' do
      allow_any_instance_of(LastfmClient).to receive(:recent_tracks).and_return([
        { name: 'Karma Police', artists: 'Radiohead', album: '', image: nil },
        { name: 'Karma Police', artists: 'Radiohead', album: '', image: nil },
        { name: 'Hey Jude', artists: 'The Beatles', album: '', image: nil }
      ])

      service = AnalyticsService.new(user)
      tracks = service.lastfm_top_tracks(limit: 3, lookback: 50)

      expect(tracks).to be_an(Array)
      expect(tracks.first[:track]).to eq('Karma Police')
      expect(tracks.first[:plays]).to eq(2)
      expect(tracks.map { |t| t[:artist] }).to include('The Beatles')
    end
  end

  describe '#user_top_rated_songs' do
    let(:user) { create(:user) }

    before do
      @song1 = create(:song, title: 'Song A', artist: 'Artist A')
      @song2 = create(:song, title: 'Song B', artist: 'Artist B')
      @song3 = create(:song, title: 'Song C', artist: 'Artist C')
    end

    it 'returns user top rated songs ordered by rating' do
      create(:review, user: user, song: @song1, rating: 5, comment: 'Excellent!!!')
      create(:review, user: user, song: @song2, rating: 4, comment: 'Very Good!')
      create(:review, user: user, song: @song3, rating: 3, comment: 'Okay Here!')

      service = AnalyticsService.new(user)
      top_songs = service.user_top_rated_songs(limit: 10).to_a

      expect(top_songs).to be_an(Array)
      expect(top_songs.length).to eq(3)
      # Should be ordered by average rating descending
      expect(top_songs.first.id).to eq(@song1.id)
    end

    it 'returns empty array when user has no reviews' do
      service = AnalyticsService.new(user)
      top_songs = service.user_top_rated_songs(limit: 10).to_a

      expect(top_songs).to be_an(Array)
      expect(top_songs).to be_empty
    end

    it 'respects limit parameter' do
      create(:review, user: user, song: @song1, rating: 5, comment: 'Test review')
      create(:review, user: user, song: @song2, rating: 4, comment: 'Test song 2')
      create(:review, user: user, song: @song3, rating: 3, comment: 'Test song 3')

      service = AnalyticsService.new(user)
      top_songs = service.user_top_rated_songs(limit: 2).to_a

      expect(top_songs.length).to eq(2)
    end

    it 'returns empty array when user is nil' do
      service = AnalyticsService.new(nil)
      top_songs = service.user_top_rated_songs(limit: 10)

      expect(top_songs).to be_an(Array)
      expect(top_songs).to be_empty
    end
  end

  describe '#aura_top_rated_songs' do
    before do
      @song1 = create(:song, title: 'Popular 1', artist: 'Artist')
      @song2 = create(:song, title: 'Popular 2', artist: 'Artist')
      @user1 = create(:user)
      @user2 = create(:user)

      create(:review, user: @user1, song: @song1, rating: 5, comment: 'Excellent!!!')
      create(:review, user: @user1, song: @song2, rating: 4, comment: 'Very Good!')
      create(:review, user: @user2, song: @song1, rating: 5, comment: 'Awesome Here!')
      create(:review, user: @user2, song: @song2, rating: 3, comment: 'Decent Sure!')
    end

    it 'returns top rated songs across all users' do
      service = AnalyticsService.new
      top_songs = service.aura_top_rated_songs(limit: 10)

      expect(top_songs).to be_an(Array)
      expect(top_songs.length).to be > 0
      # Song1 has average of 5.0, Song2 has average of 3.5
      expect(top_songs.first.id).to eq(@song1.id)
    end

    it 'respects limit parameter' do
      service = AnalyticsService.new
      top_songs = service.aura_top_rated_songs(limit: 1)

      expect(top_songs.length).to eq(1)
    end

    it 'caches results' do
      service = AnalyticsService.new
      first_call = service.aura_top_rated_songs(limit: 10)

      # Modify data
      create(:review, user: @user1, song: @song2, rating: 5, comment: 'Changed Now!')

      second_call = service.aura_top_rated_songs(limit: 10)

      # Should return cached result (same as first call)
      expect(first_call.map(&:id)).to eq(second_call.map(&:id))
    end

    it 'returns empty array when no reviews exist' do
      Review.delete_all
      service = AnalyticsService.new
      top_songs = service.aura_top_rated_songs(limit: 10)

      expect(top_songs).to be_an(Array)
      expect(top_songs).to be_empty
    end
  end

  describe '#lastfm_top_artists with no connection' do
    let(:user) { create(:user) }

    it 'returns empty array when user not Last.fm connected' do
      user.update!(lastfm_connected: false)
      service = AnalyticsService.new(user)
      artists = service.lastfm_top_artists(limit: 5)

      expect(artists).to be_an(Array)
      expect(artists).to be_empty
    end

    it 'returns empty array when user is nil' do
      service = AnalyticsService.new(nil)
      artists = service.lastfm_top_artists(limit: 5)

      expect(artists).to be_an(Array)
      expect(artists).to be_empty
    end
  end

  describe '#lastfm_top_tracks with no connection' do
    let(:user) { create(:user) }

    it 'returns empty array when user not Last.fm connected' do
      user.update!(lastfm_connected: false)
      service = AnalyticsService.new(user)
      tracks = service.lastfm_top_tracks(limit: 5)

      expect(tracks).to be_an(Array)
      expect(tracks).to be_empty
    end

    it 'returns empty array when user is nil' do
      service = AnalyticsService.new(nil)
      tracks = service.lastfm_top_tracks(limit: 5)

      expect(tracks).to be_an(Array)
      expect(tracks).to be_empty
    end
  end

  describe '#lastfm_top_artists with missing artists' do
    let(:user) { create(:user) }

    before do
      user.update!(lastfm_connected: true)
    end

    it 'handles tracks with missing artist names' do
      allow_any_instance_of(LastfmClient).to receive(:recent_tracks).and_return([
        { name: 'Song 1', artists: '', album: '', image: nil },
        { name: 'Song 2', artists: 'Artist B', album: '', image: nil }
      ])

      service = AnalyticsService.new(user)
      artists = service.lastfm_top_artists(limit: 5)

      expect(artists).to be_an(Array)
      expect(artists.length).to eq(1)
      expect(artists.first[:artist]).to eq('Artist B')
    end

    it 'handles empty recent tracks response' do
      allow_any_instance_of(LastfmClient).to receive(:recent_tracks).and_return([])

      service = AnalyticsService.new(user)
      artists = service.lastfm_top_artists(limit: 5)

      expect(artists).to be_an(Array)
      expect(artists).to be_empty
    end
  end
end
