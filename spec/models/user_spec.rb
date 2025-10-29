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
