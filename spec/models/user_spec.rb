require 'rails_helper'

RSpec.describe User, type: :model do
  describe 'validations and associations' do
    it { is_expected.to have_many(:reviews).dependent(:destroy) }
    it { is_expected.to validate_presence_of(:email) }
    it { is_expected.to validate_presence_of(:name) }
    it { is_expected.to validate_presence_of(:username) }
  it { is_expected.to validate_uniqueness_of(:email) }
  it { is_expected.to validate_uniqueness_of(:username) }
    it { is_expected.to have_secure_password }
  end

  describe '#connect_spotify_from_auth and #disconnect_spotify!' do
    let(:user) { FactoryBot.create(:user) }

    it 'saves Spotify credentials to user' do
      auth = {
        'uid' => 'spotify-uid-1',
        'credentials' => { 'token' => 'tok', 'refresh_token' => 'ref', 'expires_in' => 3600 }
      }
      user.connect_spotify_from_auth(auth)
      expect(user.spotify_uid).to eq('spotify-uid-1')
      expect(user.spotify_access_token).to eq('tok')
      expect(user.spotify_refresh_token).to eq('ref')
      expect(user.spotify_connected).to be true
    end

    it 'clears spotify credentials on disconnect' do
      user.update(spotify_uid: 'x', spotify_access_token: 't', spotify_refresh_token: 'r', spotify_connected: true)
      user.disconnect_spotify!
      expect(user.spotify_uid).to be_nil
      expect(user.spotify_access_token).to be_nil
      expect(user.spotify_refresh_token).to be_nil
      expect(user.spotify_connected).to be false
    end
  end

  describe '#spotify_access_token_with_refresh!' do
    let(:user) { FactoryBot.create(:user, spotify_refresh_token: 'ref-token') }

    it 'returns existing access token when not expired' do
      user.update(spotify_access_token: 'existing', spotify_token_expires_at: 1.hour.from_now)
      expect(user.spotify_access_token_with_refresh!).to eq('existing')
    end

    it 'refreshes token if expired and spotify_refresh_token present' do
      user.update(spotify_access_token: nil, spotify_token_expires_at: 1.hour.ago)
      allow_any_instance_of(User).to receive(:refresh_spotify_token!).and_return({ access_token: 'new-token', expires_in: 3600 })
      token = user.spotify_access_token_with_refresh!
      expect(token).to eq('new-token')
      expect(user.reload.spotify_access_token).to eq('new-token')
    end

    it 'returns nil if no refresh token available' do
      user.update(spotify_refresh_token: nil, spotify_access_token: nil, spotify_token_expires_at: nil)
      expect(user.spotify_access_token_with_refresh!).to be_nil
    end
  end
end
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
  end

  describe '#disconnect_spotify!' do
    let(:user) do
      create(:user,
        spotify_uid: 'spotify123',
        spotify_access_token: 'token',
        spotify_refresh_token: 'refresh',
        spotify_connected: true
      )
    end

    it 'clears all Spotify credentials' do
      user.disconnect_spotify!
      
      expect(user.spotify_uid).to be_nil
      expect(user.spotify_access_token).to be_nil
      expect(user.spotify_refresh_token).to be_nil
      expect(user.spotify_connected).to be false
    end
  end
end
