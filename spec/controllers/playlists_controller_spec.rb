require 'rails_helper'

RSpec.describe PlaylistsController, type: :controller do
  let(:user) { create(:user) }
  let(:playlist) { create(:playlist, user: user) }

  before do
    allow(controller).to receive(:require_login).and_return(true)
    allow(controller).to receive(:current_user).and_return(user)
  end

  describe 'POST #add_lastfm_track' do
    it 'creates a Song if missing and adds it to the playlist' do
      params = { track_name: 'New Song', artists: 'Some Artist', album_title: 'LP' }
      expect {
        post :add_lastfm_track, params: { id: playlist.id }.merge(params)
      }.to change(Song, :count).by(1)

      expect(playlist.songs.reload.map(&:title)).to include('New Song')
      expect(response).to redirect_to(playlist_path(playlist))
      expect(flash[:notice]).to be_present
    end

    it 'requires ownership to add' do
  other = create(:user, email: 'other@example.com', username: 'other')
  allow(controller).to receive(:current_user).and_return(other)
  post :add_lastfm_track, params: { id: playlist.id, track_name: 'X', artists: 'Y' }
      expect(response).to redirect_to(playlist_path(playlist))
      expect(flash[:alert]).to be_present
    end
  end
end
