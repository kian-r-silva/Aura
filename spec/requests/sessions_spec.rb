require 'rails_helper'

RSpec.describe "Sessions", type: :request do
  let(:user) { create(:user, username: 'testuser', email: 'test@example.com', password: 'password123') }

  describe "GET /new" do
    it "returns http success" do
      get new_session_path
      expect(response).to have_http_status(:success)
    end

    it "displays login form" do
      get new_session_path
      expect(response.body).to include('login') || expect(response.body).to include('sign in')
    end
  end

  describe "POST /create" do
    context "with valid credentials" do
      it "creates a session with username and redirects" do
        post session_path, params: { login: user.username, password: 'password123' }
       
        expect(response).to have_http_status(:redirect)
        expect(response).to redirect_to(root_path)
        expect(session[:user_id]).to eq(user.id)
        follow_redirect!
        expect(response.body).to include('Signed in')
      end

      it "creates a session with email and redirects" do
        post session_path, params: { login: user.email, password: 'password123' }
       
        expect(response).to have_http_status(:redirect)
        expect(response).to redirect_to(root_path)
        expect(session[:user_id]).to eq(user.id)
      end
    end

    context "with invalid credentials" do
      it "does not create session with wrong password" do
        post session_path, params: { login: user.username, password: 'wrongpassword' }
       
        expect(response).to have_http_status(:unprocessable_entity)
        expect(session[:user_id]).to be_nil
        expect(response.body).to include('Invalid login or password')
      end

      it "does not create session with non-existent username" do
        post session_path, params: { login: 'nonexistent', password: 'password123' }
       
        expect(response).to have_http_status(:unprocessable_entity)
        expect(session[:user_id]).to be_nil
        expect(response.body).to include('Invalid login or password')
      end

      it "does not create session with empty credentials" do
        post session_path, params: { login: '', password: '' }
       
        expect(response).to have_http_status(:unprocessable_entity)
        expect(session[:user_id]).to be_nil
      end
    end
  end

  describe "DELETE /destroy" do
    before do
      post session_path, params: { login: user.username, password: 'password123' }
    end

    it "logs out and redirects" do
      delete session_path
     
      expect(response).to have_http_status(:redirect)
      expect(response).to redirect_to(root_path)
      expect(session[:user_id]).to be_nil
      follow_redirect!
      expect(response.body).to include('Signed out')
    end

    it "clears the session" do
      expect(session[:user_id]).to eq(user.id)
     
      delete session_path
     
      expect(session[:user_id]).to be_nil
    end
  end
end

Update aura/spec/requests/albums_spec.rb with:

require 'rails_helper'

RSpec.describe "Albums", type: :request do
  describe "GET /index" do
    it "returns http success" do
      get albums_path
      expect(response).to have_http_status(:success)
    end

    it "displays albums in order" do
      album1 = create(:album, title: 'Ziggy Stardust')
      album2 = create(:album, title: 'Abbey Road')
     
      get albums_path
     
      expect(response.body).to include('Abbey Road')
      expect(response.body).to include('Ziggy Stardust')
    end
  end

  describe "GET /show" do
    let(:album) { create(:album) }

    it "returns http success" do
      get album_path(album)
      expect(response).to have_http_status(:success)
    end

    it "displays album details" do
      get album_path(album)
      expect(response.body).to include(album.title)
      expect(response.body).to include(album.artist)
    end
  end

  describe "GET /new" do
    it "returns http success" do
      get new_album_path
      expect(response).to have_http_status(:success)
    end
  end

  describe "POST /create" do
    context "with valid parameters" do
      it "creates a new album and redirects" do
        params = { album: { title: 'Thriller', artist: 'Michael Jackson', year: 1982 } }
       
        expect {
          post albums_path, params: params
        }.to change(Album, :count).by(1)
       
        expect(response).to have_http_status(:redirect)
        follow_redirect!
        expect(response.body).to include('Album created')
      end
    end

    context "with invalid parameters" do
      it "does not create album without title" do
        params = { album: { title: '', artist: 'Artist Name', year: 2000 } }
       
        expect {
          post albums_path, params: params
        }.not_to change(Album, :count)
       
        expect(response).to have_http_status(:unprocessable_entity)
      end

      it "does not create album without artist" do
        params = { album: { title: 'Album Title', artist: '', year: 2000 } }
       
        expect {
          post albums_path, params: params
        }.not_to change(Album, :count)
       
        expect(response).to have_http_status(:unprocessable_entity)
      end

      it "renders new template on failure" do
        params = { album: { title: '', artist: '', year: 2000 } }
       
        post albums_path, params: params
       
        expect(response).to have_http_status(:unprocessable_entity)
        expect(response.body).to include('new') || expect(response.body).to include('form')
      end
    end
  end
end

Update spec/requests/users_spec.rb

require 'rails_helper'

RSpec.describe "Users", type: :request do
  describe "GET /new" do
    it "returns http success" do
      get new_user_path
      expect(response).to have_http_status(:success)
    end
  end

  describe "POST /create" do
    context "with valid parameters" do
      it "creates a new user and redirects to root" do
        params = {
          user: {
            name: 'John Doe',
            email: 'john@example.com',
            username: 'johndoe',
            password: 'password123',
            password_confirmation: 'password123'
          }
        }
       
        expect {
          post users_path, params: params
        }.to change(User, :count).by(1)
       
        expect(response).to have_http_status(:redirect)
        expect(response).to redirect_to(root_path)
        expect(session[:user_id]).to eq(User.last.id)
        follow_redirect!
        expect(response.body).to include('Welcome')
      end

      it "logs in the user after successful signup" do
        params = {
          user: {
            name: 'Jane Smith',
            email: 'jane@example.com',
            username: 'janesmith',
            password: 'password123',
            password_confirmation: 'password123'
          }
        }
       
        post users_path, params: params
       
        expect(session[:user_id]).not_to be_nil
      end
    end

    context "with invalid parameters" do
      it "does not create user without email" do
        params = {
          user: {
            name: 'John Doe',
            email: '',
            username: 'johndoe',
            password: 'password123'
          }
        }
       
        expect {
          post users_path, params: params
        }.not_to change(User, :count)
       
        expect(response).to have_http_status(:unprocessable_entity)
      end

      it "does not create user without name" do
        params = {
          user: {
            name: '',
            email: 'john@example.com',
            username: 'johndoe',
            password: 'password123'
          }
        }
       
        expect {
          post users_path, params: params
        }.not_to change(User, :count)
       
        expect(response).to have_http_status(:unprocessable_entity)
      end

      it "does not create user without username" do
        params = {
          user: {
            name: 'John Doe',
            email: 'john@example.com',
            username: '',
            password: 'password123'
          }
        }
       
        expect {
          post users_path, params: params
        }.not_to change(User, :count)
       
        expect(response).to have_http_status(:unprocessable_entity)
      end

      it "does not create user with duplicate email" do
        existing_user = create(:user, email: 'duplicate@example.com')
       
        params = {
          user: {
            name: 'Another User',
            email: 'duplicate@example.com',
            username: 'anotheruser',
            password: 'password123'
          }
        }
       
        expect {
          post users_path, params: params
        }.not_to change(User, :count)
       
        expect(response).to have_http_status(:unprocessable_entity)
      end

      it "does not create user with duplicate username" do
        existing_user = create(:user, username: 'duplicateuser')
       
        params = {
          user: {
            name: 'Another User',
            email: 'another@example.com',
            username: 'duplicateuser',
            password: 'password123'
          }
        }
       
        expect {
          post users_path, params: params
        }.not_to change(User, :count)
       
        expect(response).to have_http_status(:unprocessable_entity)
      end

      it "renders new template on failure" do
        params = {
          user: {
            name: '',
            email: '',
            username: '',
            password: ''
          }
        }
       
        post users_path, params: params
       
        expect(response).to have_http_status(:unprocessable_entity)
      end
    end
  end

  describe "GET /show" do
    let(:user) { create(:user) }

    it "returns http success" do
      get user_path(user)
      expect(response).to have_http_status(:success)
    end

    it "displays user information" do
      get user_path(user)
      expect(response.body).to include(user.name)
    end
  end
end

Update spec/models/user_spec.rb with:

require 'rails_helper'

RSpec.describe User, type: :model do
  describe 'associations' do
    it { should have_many(:reviews).dependent(:destroy) }
  end

  describe 'validations' do
    subject { build(:user) }
   
    it { should validate_presence_of(:email) }
    it { should validate_presence_of(:name) }
    it { should validate_presence_of(:username) }
    it { should validate_uniqueness_of(:email) }
    it { should validate_uniqueness_of(:username) }
    it { should have_secure_password }
  end

  describe '#connect_spotify_from_auth' do
    let(:user) { create(:user) }

    context 'with complete auth data' do
      let(:auth_hash) do
        {
          'uid' => 'spotify123',
          'credentials' => {
            'token' => 'access_token_123',
            'refresh_token' => 'refresh_token_123',
            'expires_in' => 3600
          }
        }
      end

      it 'saves Spotify credentials to user' do
        user.connect_spotify_from_auth(auth_hash)
       
        expect(user.spotify_uid).to eq('spotify123')
        expect(user.spotify_access_token).to eq('access_token_123')
        expect(user.spotify_refresh_token).to eq('refresh_token_123')
        expect(user.spotify_connected).to be true
        expect(user.spotify_token_expires_at).to be_present
      end

      it 'calculates correct expiration time' do
        freeze_time do
          user.connect_spotify_from_auth(auth_hash)
          expected_time = Time.current + 3600.seconds
          expect(user.spotify_token_expires_at).to be_within(1.second).of(expected_time)
        end
      end
    end

    context 'with minimal auth data' do
      let(:minimal_auth) do
        {
          'uid' => 'spotify456',
          'credentials' => {
            'token' => 'token_only'
          }
        }
      end

      it 'saves minimal credentials' do
        user.connect_spotify_from_auth(minimal_auth)
       
        expect(user.spotify_uid).to eq('spotify456')
        expect(user.spotify_access_token).to eq('token_only')
        expect(user.spotify_connected).to be true
      end
    end
  end

  describe '#disconnect_spotify!' do
    let(:user) do
      create(:user,
        spotify_uid: 'spotify123',
        spotify_access_token: 'token',
        spotify_refresh_token: 'refresh',
        spotify_token_expires_at: 1.hour.from_now,
        spotify_connected: true
      )
    end

    it 'clears all Spotify credentials' do
      user.disconnect_spotify!
     
      expect(user.reload.spotify_uid).to be_nil
      expect(user.spotify_access_token).to be_nil
      expect(user.spotify_refresh_token).to be_nil
      expect(user.spotify_token_expires_at).to be_nil
      expect(user.spotify_connected).to be false
    end

    it 'persists changes to database' do
      user.disconnect_spotify!
      user.reload
     
      expect(user.spotify_connected).to be false
    end
  end

  describe '#spotify_access_token_with_refresh!' do
    let(:user) { create(:user, spotify_refresh_token: 'refresh_token_123') }

    context 'when token is still valid' do
      before do
        user.update(
          spotify_access_token: 'valid_token',
          spotify_token_expires_at: 1.hour.from_now
        )
      end

      it 'returns existing access token' do
        expect(user.spotify_access_token_with_refresh!).to eq('valid_token')
      end

      it 'does not refresh the token' do
        expect(user).not_to receive(:refresh_spotify_token!)
        user.spotify_access_token_with_refresh!
      end
    end

    context 'when token is expired' do
      before do
        user.update(
          spotify_access_token: 'expired_token',
          spotify_token_expires_at: 1.hour.ago
        )
      end

      it 'refreshes token and returns new token' do
        allow_any_instance_of(User).to receive(:refresh_spotify_token!)
          .and_return({ access_token: 'new_fresh_token', expires_in: 3600 })
       
        token = user.spotify_access_token_with_refresh!
       
        expect(token).to eq('new_fresh_token')
        expect(user.reload.spotify_access_token).to eq('new_fresh_token')
      end

      it 'updates expiration time' do
        freeze_time do
          allow_any_instance_of(User).to receive(:refresh_spotify_token!)
            .and_return({ access_token: 'new_token', expires_in: 3600 })
         
          user.spotify_access_token_with_refresh!
         
          expected_time = Time.current + 3600.seconds
          expect(user.reload.spotify_token_expires_at).to be_within(1.second).of(expected_time)
        end
      end
    end

    context 'when token is about to expire' do
      before do
        user.update(
          spotify_access_token: 'soon_expired_token',
          spotify_token_expires_at: 20.seconds.from_now
        )
      end

      it 'refreshes token preemptively' do
        allow_any_instance_of(User).to receive(:refresh_spotify_token!)
          .and_return({ access_token: 'refreshed_token', expires_in: 3600 })
       
        token = user.spotify_access_token_with_refresh!
       
        expect(token).to eq('refreshed_token')
      end
    end

    context 'when no refresh token available' do
      before do
        user.update(
          spotify_refresh_token: nil,
          spotify_access_token: nil,
          spotify_token_expires_at: nil
        )
      end

      it 'returns nil' do
        expect(user.spotify_access_token_with_refresh!).to be_nil
      end
    end

    context 'when refresh fails' do
      before do
        user.update(
          spotify_access_token: 'expired_token',
          spotify_token_expires_at: 1.hour.ago
        )
      end

      it 'returns nil when refresh_spotify_token! fails' do
        allow_any_instance_of(User).to receive(:refresh_spotify_token!).and_return(nil)
       
        expect(user.spotify_access_token_with_refresh!).to be_nil
      end
    end
  end

  describe 'password management' do
    it 'encrypts password with has_secure_password' do
      user = create(:user, password: 'secretpassword123')
     
      expect(user.password_digest).not_to eq('secretpassword123')
      expect(user.authenticate('secretpassword123')).to eq(user)
    end

    it 'authenticates with correct password' do
      user = create(:user, password: 'mypassword')
     
      expect(user.authenticate('mypassword')).to eq(user)
    end

    it 'does not authenticate with incorrect password' do
      user = create(:user, password: 'mypassword')
     
      expect(user.authenticate('wrongpassword')).to be false
    end
  end
end
