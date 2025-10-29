require 'rails_helper'

RSpec.describe SpotifyController, type: :controller do
  let(:user) { FactoryBot.create(:user) }

  before do
    allow(controller).to receive(:current_user).and_return(user)
  end

  describe 'GET #recent' do
    it 'renders recent and assigns tracks' do
      user.update(spotify_connected: true)
      allow_any_instance_of(SpotifyClient).to receive(:recent_tracks).and_return([{ 'id' => '1', 'name' => 'Song' }])
      get :recent
      expect(response).to have_http_status(:ok)
      tracks = controller.instance_variable_get(:@tracks)
      expect(tracks).to be_present
    end
  end

  describe 'GET #search' do
    it 'returns results for query' do
      user.update(spotify_connected: true)
      allow_any_instance_of(SpotifyClient).to receive(:search_tracks).and_return([{ 'id' => '1', 'name' => 'Hey Jude' }])
      get :search, params: { q: 'beatles' }
      expect(response).to have_http_status(:ok)
      tracks = controller.instance_variable_get(:@tracks)
      expect(tracks).to be_present
    end
  end
end
