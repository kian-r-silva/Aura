require 'rails_helper'

RSpec.describe User, type: :model do
  describe 'validations and associations' do
    subject { build(:user) }

    it { is_expected.to have_many(:reviews).dependent(:destroy) }
    it { is_expected.to validate_presence_of(:email) }
    it { is_expected.to validate_presence_of(:name) }
    it { is_expected.to validate_presence_of(:username) }
    it { is_expected.to validate_uniqueness_of(:email) }
    it { is_expected.to validate_uniqueness_of(:username) }
    it { is_expected.to have_secure_password }
  end

  describe 'spotify token flows' do
    let(:user) { create(:user) }

    it 'returns existing token when not expired' do
      user.update!(spotify_access_token: 't', spotify_token_expires_at: 1.hour.from_now)
      expect(user.spotify_access_token_with_refresh!).to eq('t')
    end

    it 'returns nil when expired and no refresh token' do
      user.update!(spotify_access_token: nil, spotify_token_expires_at: 1.hour.ago, spotify_refresh_token: nil)
      expect(user.spotify_access_token_with_refresh!).to be_nil
    end

    it 'refreshes and returns token when refresh available' do
      user.update!(spotify_access_token: nil, spotify_token_expires_at: 1.hour.ago, spotify_refresh_token: 'r')
      allow_any_instance_of(User).to receive(:refresh_spotify_token!).and_return({ access_token: 'new', expires_in: 3600 })

      expect(user.spotify_access_token_with_refresh!).to eq('new')
      expect(user.reload.spotify_access_token).to eq('new')
    end

    it 'returns nil if refresh_spotify_token! returns nil' do
      user.update!(spotify_access_token: nil, spotify_token_expires_at: 1.hour.ago, spotify_refresh_token: 'r')
      allow_any_instance_of(User).to receive(:refresh_spotify_token!).and_return(nil)

      expect(user.spotify_access_token_with_refresh!).to be_nil
    end
  end

  describe '#connect_spotify_from_auth and #disconnect_spotify!' do
    let(:user) { create(:user) }

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
      user.update!(spotify_uid: 'x', spotify_access_token: 't', spotify_refresh_token: 'r', spotify_connected: true)
      user.disconnect_spotify!
      user.reload
      expect(user.spotify_uid).to be_nil
      expect(user.spotify_access_token).to be_nil
      expect(user.spotify_refresh_token).to be_nil
      expect(user.spotify_connected).to be false
    end
  end

  describe 'refresh_spotify_token! low-level' do
    let(:user) { create(:user) }

    it 'returns parsed token when http success' do
      ENV['SPOTIFY_CLIENT_ID'] = 'cid'
      ENV['SPOTIFY_CLIENT_SECRET'] = 'sec'
      user.update!(spotify_refresh_token: 'r')

      fake_res = double('res', body: { access_token: 'a', expires_in: 10 }.to_json)
      allow(fake_res).to receive(:is_a?).with(Net::HTTPSuccess).and_return(true)
      allow(Net::HTTP).to receive(:start).and_return(fake_res)

      out = user.send(:refresh_spotify_token!)
      expect(out[:access_token]).to eq('a')
    end

    it 'returns nil when http not success' do
      ENV['SPOTIFY_CLIENT_ID'] = 'cid'
      ENV['SPOTIFY_CLIENT_SECRET'] = 'sec'
      user.update!(spotify_refresh_token: 'r')

      fake_res = double('res')
      allow(fake_res).to receive(:is_a?).with(Net::HTTPSuccess).and_return(false)
      allow(Net::HTTP).to receive(:start).and_return(fake_res)

      expect(user.send(:refresh_spotify_token!)).to be_nil
    end
  end
end
