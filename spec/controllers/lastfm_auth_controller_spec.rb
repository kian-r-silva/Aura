require 'rails_helper'

RSpec.describe LastfmAuthController, type: :controller do
  let(:user) { User.create!(email: 'la@example.com', name: 'LA', username: 'la1', password: 'password') }

  before do
    allow(controller).to receive(:require_login).and_return(true)
    allow(controller).to receive(:current_user).and_return(user)
  end

  describe 'GET #auth' do
    it 'redirects to root when api key missing' do
      ENV['LASTFM_API_KEY'] = nil
      get :auth
      expect(response).to redirect_to(root_path)
      expect(flash[:alert]).to be_present
    end

    it 'redirects to last.fm when api key present' do
      ENV['LASTFM_API_KEY'] = 'k'
      get :auth
      expect(response).to have_http_status(:redirect)
      expect(response.location).to include('last.fm')
    end
  end

  describe 'GET #callback' do
    it 'redirects with alert when no token' do
      get :callback
      expect(response).to redirect_to(root_path)
      expect(flash[:alert]).to be_present
    end

    it 'redirects with alert when get_session fails' do
      allow(LastfmClient).to receive(:get_session).and_return(nil)
      get :callback, params: { token: 't' }
      expect(response).to redirect_to(root_path)
      expect(flash[:alert]).to be_present
    end

    it 'connects user when get_session succeeds' do
      allow(LastfmClient).to receive(:get_session).and_return({ session_key: 's', username: 'bob' })
      expect_any_instance_of(User).to receive(:connect_lastfm_from_session).with('s', 'bob')
      get :callback, params: { token: 't' }
      expect(response).to redirect_to(root_path)
      expect(flash[:notice]).to be_present
    end
  end

  describe 'POST #disconnect' do
    it 'disconnects the current user and redirects' do
      expect_any_instance_of(User).to receive(:disconnect_lastfm!)
      get :disconnect
      expect(response).to redirect_to(root_path)
    end
  end

  describe 'GET #token' do
    it 'returns unauthorized when no session_key' do
      user.update!(lastfm_session_key: nil)
      get :token
      expect(response).to have_http_status(:unauthorized)
      json = JSON.parse(response.body)
      expect(json['error']).to eq('no_session')
    end

    it 'returns session_key when present' do
      user.update!(lastfm_session_key: 'abc')
      get :token
      expect(response).to have_http_status(:ok)
      json = JSON.parse(response.body)
      expect(json['session_key']).to eq('abc')
    end
  end
end
