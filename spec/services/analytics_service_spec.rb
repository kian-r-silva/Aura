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
end
