require 'rails_helper'

RSpec.describe SpotifyAuthController, type: :controller do
  let(:user) { FactoryBot.create(:user) }

  before do
    # sign in by stubbing current_user via session
    allow(controller).to receive(:current_user).and_return(user)
  end

  describe 'GET #callback' do
    it 'connects spotify account from omniauth payload' do
      auth = OmniAuth::AuthHash.new(provider: 'spotify', uid: 'uid1', credentials: { token: 't', refresh_token: 'r', expires_in: 3600 })
      request.env['omniauth.auth'] = auth
      get :callback
      expect(response).to redirect_to(root_path)
      expect(flash[:notice]).to eq('Spotify account connected')
      expect(user.reload.spotify_uid).to eq('uid1')
    end

    it 'redirects with alert if no auth present' do
      request.env['omniauth.auth'] = nil
      get :callback
      expect(response).to redirect_to(root_path)
      expect(flash[:alert]).to be_present
    end
  end

  describe 'DELETE #disconnect' do
    it 'disconnects spotify and redirects' do
      user.update(spotify_connected: true, spotify_uid: 'x')
      delete :disconnect
      expect(response).to redirect_to(root_path)
      expect(flash[:notice]).to eq('Spotify disconnected')
      expect(user.reload.spotify_connected).to be false
    end
  end

  describe 'GET #token' do
    it 'returns access token when present' do
      allow(user).to receive(:spotify_access_token_with_refresh!).and_return('fresh-token')
      get :token
      expect(response).to have_http_status(:ok)
      expect(JSON.parse(response.body)['access_token']).to eq('fresh-token')
    end

    it 'returns unauthorized when no token' do
      allow(user).to receive(:spotify_access_token_with_refresh!).and_return(nil)
      get :token
      expect(response).to have_http_status(:unauthorized)
    end
  end
end
